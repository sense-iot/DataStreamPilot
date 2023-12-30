#import os
from influxdb import InfluxDBClient
from datetime import datetime, timedelta


from configuration import HOST, PORT, USERNAME, PASSWORD, DATABASE, TEMPERATURE, sites
import random
import time

async def client():
    # InfluxDB client setup
    client = InfluxDBClient(host=HOST, port=int(PORT), username=USERNAME, password=PASSWORD)

    client.create_database(DATABASE)
    client.switch_database(DATABASE)
    
    return client


def getInfluxDB(query, measurement=TEMPERATURE):
    db_client = client()
    result = db_client.query(query=query)
    output = []
    for key, value in enumerate(result):
        output.append(value)  
    return output


async def sendInfluxdb(decodedValue, site, sensor):
    db_client = await client()
    tags        = {"place": sites[site], "sensor": sensor}
    # base_timestamp = datetime.utcnow() - timedelta(seconds=len(decodedValues))

    fields      = { "value" : decodedValue}

    await save(db_client, sites[site], fields, tags=tags, timestamp=datetime.utcnow())    
    
    return True


async def save(db_client, measurement, fields, tags=None, timestamp=None):
    json_body = [{'measurement': measurement, 'tags': tags, 'fields': fields, 'time': timestamp}]

    # write / save into a row
    db_client.write_points(json_body)