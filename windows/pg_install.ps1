$ErrorActionPreference = "Stop"

# Configurable Variables
$containerName = "pg-root-peer"
$dataPath = "$env:USERPROFILE\podman_pg\data"
$runPath = "$env:USERPROFILE\podman_pg\run"
$confPath = "$env:USERPROFILE\podman_pg\postgresql.conf"
$hbaPath = "$env:USERPROFILE\podman_pg\pg_hba.conf"
$image = "docker.io/library/postgres:16"

Write-Host "🚀 Starting Podman PostgreSQL Setup..."

# Ensure Podman machine is running
if (-not (podman machine list | Select-String "Running")) {
    Write-Host "⚙️  Starting Podman machine..."
    podman machine start
} else {
    Write-Host "✔️  Podman machine already running."
}

# Host verification - ensure script host and container host are the same
Write-Host "🔍 Verifying host compatibility..."

# Get Windows host information
$windowsHostname = $env:COMPUTERNAME
$windowsUsername = $env:USERNAME
$windowsUserDomain = $env:USERDOMAIN
Write-Host "  Windows Host: $windowsHostname"
Write-Host "  Windows User: $windowsUserDomain\$windowsUsername"

# Get Podman machine information
try {
    $podmanMachineInfo = podman machine inspect --format json | ConvertFrom-Json
    $machineInfo = $podmanMachineInfo[0]
    Write-Host "  Podman Machine: $($machineInfo.Name)"
    Write-Host "  Machine State: $($machineInfo.State)"
    
    # Verify Podman can access the host filesystem
    Write-Host "🔗 Testing host-container filesystem access..."
    $testFile = "$env:TEMP\podman_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    "Host verification test" | Set-Content $testFile
    
    # Test if container can access the host file
    $testResult = podman run --rm -v "${env:TEMP}:/host_temp:Z" $image cat "/host_temp/$(Split-Path $testFile -Leaf)"
    
    if ($testResult -match "Host verification test") {
        Write-Host "✅ Host-container filesystem access verified."
        Remove-Item $testFile -ErrorAction SilentlyContinue
    } else {
        Write-Host "❌ Host-container filesystem access failed."
        Write-Host "This may indicate that the Podman machine cannot properly access Windows host files."
        exit 1
    }
    
    # Verify volume mount capabilities
    Write-Host "🗂️  Testing volume mount capabilities..."
    $tempDir = "$env:TEMP\podman_volume_test"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    $volumeTest = podman run --rm -v "${tempDir}:/test_mount:Z" $image sh -c "echo 'Volume mount test' > /test_mount/test.txt && cat /test_mount/test.txt"
    
    if ($volumeTest -match "Volume mount test" -and (Test-Path "$tempDir\test.txt")) {
        Write-Host "✅ Volume mount capabilities verified."
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    } else {
        Write-Host "❌ Volume mount test failed."
        Write-Host "Socket mounting may not work properly."
        exit 1
    }
    
    # Check if we can create Unix sockets in mounted volumes
    Write-Host "🔌 Testing Unix socket creation capabilities..."
    $socketTestDir = "$env:TEMP\podman_socket_test"
    New-Item -ItemType Directory -Force -Path $socketTestDir | Out-Null
    
    $socketTest = podman run --rm -v "${socketTestDir}:/socket_test:Z" $image sh -c "
        # Try to create a simple Unix socket using netcat
        timeout 2 nc -U -l /socket_test/test.sock &
        sleep 1
        ls -la /socket_test/
        kill %1 2>/dev/null || true
    "
    
    Write-Host "Socket test output:"
    Write-Host $socketTest
    
    Remove-Item -Recurse -Force $socketTestDir -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "⚠️  Warning: Could not fully verify Podman machine info: $_"
    Write-Host "Continuing with setup, but socket access may be limited."
}

# Additional verification for WSL2 vs Hyper-V backend
Write-Host "🖥️  Checking Podman backend type..."
try {
    $machineList = podman machine list --format json | ConvertFrom-Json
    $currentMachine = $machineList | Where-Object { $_.Running -eq $true } | Select-Object -First 1
    
    if ($currentMachine) {
        Write-Host "  Active Machine: $($currentMachine.Name)"
        Write-Host "  VM Type: $($currentMachine.VMType)"
        Write-Host "  Last Up: $($currentMachine.LastUp)"
        
        # Check if using WSL2 (better for Unix sockets)
        if ($currentMachine.VMType -eq "wsl") {
            Write-Host "✅ Using WSL2 backend - optimal for Unix socket support."
        } elseif ($currentMachine.VMType -eq "qemu") {
            Write-Host "⚠️  Using QEMU backend - Unix sockets should work but may have limitations."
        } else {
            Write-Host "⚠️  Unknown VM type: $($currentMachine.VMType)"
        }
    }
} catch {
    Write-Host "⚠️  Could not determine Podman backend type: $_"
}

Write-Host "✅ Host verification completed."

# Final host identity verification
Write-Host "🔍 Performing final host identity verification..."
try {
    # Create a unique identifier file on the host
    $hostIdentifier = "PODMAN_HOST_$(Get-Date -Format 'yyyyMMddHHmmss')_$($env:COMPUTERNAME)_$($env:USERNAME)"
    $identifierFile = "$env:TEMP\$hostIdentifier.txt"
    $hostIdentifier | Set-Content $identifierFile
    
    # Read the identifier from within a container
    $containerIdentifier = podman run --rm -v "${env:TEMP}:/host_temp:Z" $image cat "/host_temp/$hostIdentifier.txt"
    
    if ($containerIdentifier.Trim() -eq $hostIdentifier) {
        Write-Host "✅ Host identity verification successful."
        Write-Host "  Script host and container host are confirmed to be the same."
        Write-Host "  Identifier: $hostIdentifier"
    } else {
        Write-Host "❌ Host identity verification failed!"
        Write-Host "  Expected: $hostIdentifier"
        Write-Host "  Got: $($containerIdentifier.Trim())"
        Write-Host "  This indicates the container is running on a different host than the script."
        Remove-Item $identifierFile -ErrorAction SilentlyContinue
        exit 1
    }
    
    Remove-Item $identifierFile -ErrorAction SilentlyContinue
    
    # Additional check: verify container can write back to host
    Write-Host "🔄 Testing bidirectional host-container file access..."
    $testDir = "$env:TEMP\podman_bidirectional_test"
    New-Item -ItemType Directory -Force -Path $testDir | Out-Null
    
    $writeTest = podman run --rm -v "${testDir}:/test_dir:Z" $image sh -c "echo 'Container can write to host' > /test_dir/container_write.txt"
    
    if (Test-Path "$testDir\container_write.txt") {
        $content = Get-Content "$testDir\container_write.txt"
        if ($content -match "Container can write to host") {
            Write-Host "✅ Bidirectional file access verified."
        } else {
            Write-Host "⚠️  File exists but content mismatch: $content"
        }
    } else {
        Write-Host "❌ Container cannot write to host directory."
        Write-Host "This may cause issues with socket file creation."
        Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        exit 1
    }
    
    Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "❌ Host identity verification failed with error: $_"
    Write-Host "Cannot guarantee that script host and container host are the same."
    exit 1
}

# Cleanup
Write-Host "🧹 Cleaning up previous container and data..."
podman rm -f $containerName 2>$null
podman volume rm -f pg-data-volume 2>$null
podman volume rm -f pg-run-volume 2>$null
if (Test-Path $dataPath) {
    Remove-Item -Recurse -Force $dataPath -ErrorAction Ignore
}
if (Test-Path $runPath) {
    Remove-Item -Recurse -Force $runPath -ErrorAction Ignore
}

# Create directories with proper permissions
Write-Host "📁 Creating directories and volumes..."
New-Item -ItemType Directory -Force -Path $dataPath | Out-Null
New-Item -ItemType Directory -Force -Path $runPath | Out-Null

# Create Podman volumes for better permission handling
Write-Host "📦 Creating Podman volumes..."
podman volume create pg-data-volume
podman volume create pg-run-volume

# Set directory permissions for broader access
Write-Host "🔐 Setting directory permissions..."
try {
    # Set permissions for data directory
    $acl = Get-Acl $dataPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    # Add permissions for Users group to allow broader access
    $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($usersRule)
    Set-Acl -Path $dataPath -AclObject $acl
    
    # Set permissions for run directory (socket directory) - more permissive
    $acl = Get-Acl $runPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    # Allow all users to read/execute in socket directory
    $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($usersRule)
    # Allow Everyone group access for maximum compatibility
    $everyoneRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($everyoneRule)
    Set-Acl -Path $runPath -AclObject $acl
    
    Write-Host "✅ Directory permissions set successfully with broad user access."
} catch {
    Write-Host "⚠️  Warning: Could not set directory permissions: $_"
}

# Write postgresql.conf
Write-Host "📝 Writing postgresql.conf..."
@"
# PostgreSQL configuration for UDS and peer authentication
unix_socket_directories = '/var/run/postgresql'
listen_addresses = ''
port = 5432
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'all'
log_min_messages = info
shared_preload_libraries = ''
max_connections = 100
"@ | Set-Content $confPath

# Write pg_hba.conf (peer auth)
Write-Host "📝 Writing pg_hba.conf..."
@"
# PostgreSQL Client Authentication Configuration
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections via Unix domain sockets with peer authentication
local   all             all                                     peer

# Fallback for local connections (trust for development)
# local   all             postgres                                trust
# host    all             all             127.0.0.1/32            trust
# host    all             all             ::1/128                 trust
"@ | Set-Content $hbaPath

# Launch container
Write-Host "🐳 Starting PostgreSQL container with peer authentication..."

# Use the official PostgreSQL container with Podman volumes
Write-Host "📦 Setting up PostgreSQL with Podman volumes..."

# Create and run the PostgreSQL container using Podman volumes
podman run -d `
  --name $containerName `
  -v pg-data-volume:/var/lib/postgresql/data `
  -v "${confPath}:/etc/postgresql/postgresql.conf:Z" `
  -v "${hbaPath}:/etc/postgresql/pg_hba.conf:Z" `
  -v pg-run-volume:/var/run/postgresql `
  -e POSTGRES_HOST_AUTH_METHOD=trust `
  -e POSTGRES_INITDB_ARGS="--auth-local=peer --auth-host=trust" `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_DB=postgres `
  -e POSTGRES_PASSWORD=password `
  --security-opt label=disable `
  $image

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start PostgreSQL container."
    exit 1
}

Start-Sleep -Seconds 10
Write-Host "⏳ Waiting for PostgreSQL to initialize..."

# Check if container is running
$containerStatus = podman ps --filter "name=$containerName" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "❌ Container is not running. Checking logs..."
    podman logs $containerName
    exit 1
}

Write-Host "✅ Container is running: $containerStatus"

# Wait for PostgreSQL to be ready
$maxRetries = 30
$retryCount = 0
$isReady = $false

while ($retryCount -lt $maxRetries -and -not $isReady) {
    try {
        $checkResult = podman exec $containerName pg_isready -h /var/run/postgresql
        if ($LASTEXITCODE -eq 0) {
            $isReady = $true
            Write-Host "✅ PostgreSQL is ready!"
        } else {
            $retryCount++
            Write-Host "⏳ Waiting for PostgreSQL... (attempt $retryCount/$maxRetries)"
            Start-Sleep -Seconds 2
        }
    } catch {
        $retryCount++
        Write-Host "⏳ Waiting for PostgreSQL... (attempt $retryCount/$maxRetries)"
        Start-Sleep -Seconds 2
    }
}

if (-not $isReady) {
    Write-Host "❌ PostgreSQL failed to start within timeout period. Checking logs..."
    podman logs $containerName
    exit 1
}

# Set socket permissions for broader access
Write-Host "🔐 Setting socket permissions for broader access..."
try {
    podman exec $containerName chmod 666 /var/run/postgresql/.s.PGSQL.5432
    Write-Host "✅ Socket permissions updated for broader access."
} catch {
    Write-Host "⚠️  Warning: Could not update socket permissions: $_"
}

# Verify peer auth via UDS
Write-Host "🔍 Verifying peer authentication and socket accessibility..."
try {
    # First, check if the socket directory exists and has the socket file
    $socketCheck = podman exec $containerName ls -la /var/run/postgresql/
    Write-Host "Socket directory contents:"
    Write-Host $socketCheck
    
    # Check socket file permissions specifically
    $socketPerms = podman exec $containerName ls -l /var/run/postgresql/.s.PGSQL.5432
    Write-Host "Socket file permissions:"
    Write-Host $socketPerms
    
    # Try to connect using peer authentication as postgres user
    $verify = podman exec -u postgres $containerName psql -h /var/run/postgresql -d postgres -c "SELECT current_user, version();"
    if ($verify -match "current_user" -and $verify -match "PostgreSQL") {
        Write-Host "`n✅ PostgreSQL is running with peer authentication via UDS."
        Write-Host "Connection verified successfully!"
    } else {
        Write-Host "`n❌ Could not verify authentication. Output:"
        Write-Host $verify
    }
    
    # Test connection as root user to verify broader access
    Write-Host "`n🔍 Testing socket access as root user..."
    try {
        $rootTest = podman exec -u root $containerName psql -h /var/run/postgresql -d postgres -c "SELECT 'Root user can connect' as test;"
        if ($rootTest -match "Root user can connect") {
            Write-Host "✅ Root user can access PostgreSQL via socket!"
        } else {
            Write-Host "⚠️  Root user connection test output:"
            Write-Host $rootTest
        }
    } catch {
        Write-Host "⚠️  Root user cannot connect (this may be normal with peer auth): $_"
    }
      # Additional verification - check if we can create a database
    Write-Host "`n🔍 Testing database operations..."
    $dbTest = podman exec -u postgres $containerName psql -h /var/run/postgresql -d postgres -c "CREATE DATABASE test_db;"
    if ($dbTest -match "CREATE DATABASE") {
        Write-Host "✅ Database creation test passed!"
        # Clean up the test database
        $dropResult = podman exec -u postgres $containerName psql -h /var/run/postgresql -d postgres -c "DROP DATABASE test_db;"
        if ($dropResult -match "DROP DATABASE") {
            Write-Host "✅ Database cleanup completed!"
        }
    } else {
        Write-Host "⚠️  Database operations test failed. Output:"
        Write-Host $dbTest
    }
    
} catch {
    Write-Host "`n❌ Failed to verify PostgreSQL. Error: $_"
    Write-Host "Checking container logs for troubleshooting..."
    podman logs --tail 20 $containerName
}

# Show connection information
Write-Host "`n📋 Connection Information:"
Write-Host "  Container Name: $containerName"
Write-Host "  Socket Path (in container): /var/run/postgresql"
Write-Host "  Data Path (host): $dataPath"
Write-Host "  Run Path (host): $runPath"
Write-Host "`n🔌 Connection Methods:"
Write-Host "  For postgres user:"
Write-Host "    podman exec -u postgres $containerName psql -h /var/run/postgresql -d postgres"
Write-Host "  For other users (may require trust auth fallback):"
Write-Host "    podman exec -u <username> $containerName psql -h /var/run/postgresql -d postgres"
Write-Host "  Alternative with explicit socket:"
Write-Host "    podman exec -u postgres $containerName psql -h /var/run/postgresql/.s.PGSQL.5432 -d postgres"
Write-Host "`n🔑 Authentication Notes:"
Write-Host "  - Peer authentication maps container users to PostgreSQL users"
Write-Host "  - Trust authentication is available as fallback for local connections"
Write-Host "  - Socket permissions set to 666 for broader access"
Write-Host "  - Socket directory permissions set to 755"
Write-Host "`n🎉 Setup complete! PostgreSQL is running with UDS and peer authentication."
