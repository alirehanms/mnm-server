# Start-Grafana.ps1

# Function to check if Podman is installed
function Ensure-Podman {
    if (-not (Get-Command "podman" -ErrorAction SilentlyContinue)) {
        Write-Host "Podman is not installed. Installing via winget..."
        winget install -e --id RedHat.Podman
    } else {
        Write-Host "Podman is already installed."
    }
}

# Step 1: Ensure Podman is installed
Ensure-Podman

# Step 2: Define container and volume names
$containerName = "grafana"
$volumeName = "grafana-data"
$hostPort = 9000
$containerPort = 3000

# Step 3: Create Podman volume (persistent storage)
if (-not (podman volume exists $volumeName)) {
    Write-Host "Creating volume: $volumeName"
    podman volume create $volumeName
} else {
    Write-Host "Volume '$volumeName' already exists."
}

# Step 4: Stop and remove existing container if it exists
if (podman container exists $containerName) {
    Write-Host "Removing existing container: $containerName"
    podman stop $containerName
    podman rm $containerName
}

# Step 5: Pull Grafana image
Write-Host "Pulling Grafana image..."
podman pull grafana/grafana-oss

# Step 6: Run Grafana container
Write-Host "Starting Grafana container..."
podman run -d `
    --name $containerName `
    -p ${hostPort}:$containerPort `
    -v ${volumeName}:/var/lib/grafana `
    grafana/grafana-oss

# Step 7: Final output
Write-Host "`nGrafana is running!"
Write-Host "Access it at: http://localhost:$hostPort"
