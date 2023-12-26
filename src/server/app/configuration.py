import os



# ------------------------------  from database.py file ------------------------------ # 
# InfluxDB credentials
#HOST      = os.environ.get('INFLUXDB_HOST', '192.168.1.172')
HOST     = os.environ.get('INFLUXDB_HOST', '172.17.0.1')
PORT     = os.environ.get('INFLUXDB_PORT', 8086)
USERNAME = os.environ.get('INFLUXDB_USER', 'iotmini2')
PASSWORD = os.environ.get('INFLUXDB_USER_PASSWORD', 'sense')
DATABASE = os.environ.get('INFLUXDB_DB', 'dht')

# measurements/tables
TEMPERATURE = 'temperature'
HUMIDITY    = 'humidity'

sites = {"0": "UNKNOWN", "1": "grenoble", "2": "paris", "3": "lille", "4": "saclay", "5": "strasbourg"}