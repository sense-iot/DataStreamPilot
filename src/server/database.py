#import os
from influxdb import InfluxDBClient

from configuration import HOST, PORT, USERNAME, PASSWORD, DATABASE, TEMPERATURE, sites
import random
import time

def client():
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


def sendInfluxdb(decodedValues, site, filteredValues):
    db_client = client()
    tags        = {"place": sites[site]}
    for i in range(len(decodedValues)):
        fields      = { "value" : decodedValues[i], "filtered" : filteredValues[i] }
        save(db_client, TEMPERATURE, fields, tags=tags)    
        time.sleep(1)


def save(db_client, measurement, fields, tags=None):
    json_body = [{'measurement': measurement, 'tags': tags, 'fields': fields}]

    # write / save into a row
    db_client.write_points(json_body)