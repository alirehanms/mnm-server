if [ $# -eq 0 ]; then
  echo "No arguments provided."
  exit 1
fi

# Access individual arguments
echo "First argument: $1"
echo "Second argument: $2"

# Loop through all arguments
echo "All arguments:"
for arg in "$@"; do
  echo "$arg"
done

fileName='/etc/mysql/mysql.conf.d/mysqld.cnf'
paramName='innodb_buffer_pool_size'
value='1000000000'
grep -q "^[[:space:]]*#*[[:space:]]*$paramName" $fileName && sed -i 's/^[[:space:]]*#*[[:space:]]*$paramName.*/$paramName=$value/' $fileName || echo "$paramName=$value" >>$fileName

mysql -e "SET GLOBAL $paramName=$value"
