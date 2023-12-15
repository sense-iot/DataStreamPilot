import datetime
import logging
import json
import asyncio

import aiocoap.resource as resource
from aiocoap.numbers.contentformat import ContentFormat
import aiocoap

from database import client, getInfluxDB, sendInfluxdb
from configuration import TEMPERATURE

from decoder import decodeTemperature

# logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("coap-server")
logger.setLevel(logging.DEBUG)

class TimeResource(resource.ObservableResource):
    async def render_get(self, request):
        payload = datetime.datetime.now().\
                strftime("%Y-%m-%d %H:%M").encode('ascii')
        return aiocoap.Message(payload=payload)

class Temperature(resource.Resource):
    async def render_post(self, request):
        payload = json.loads(request.payload.decode('utf8'))
        logger.debug(f"Received message: {payload}")

        decodedValues, filteredValues = await decodeTemperature(payload['temperature'])
        logger.debug(f"Decoded values: {decodedValues}, Filtered values: {filteredValues}")

        recordedFlag = await sendInfluxdb(decodedValues, payload['site'], filteredValues)
        logger.debug(f"Recorded flag: {recordedFlag}")

        return aiocoap.Message(content_format=0,
                payload=json.dumps({"status": "ok"}).encode('utf8'))

async def main():
    # Resource tree creation
    root = resource.Site()

    root.add_resource(['.well-known', 'core'],
            resource.WKCResource(root.get_resources_as_linkheader))
    root.add_resource(['time'], TimeResource())
    root.add_resource(['temp'], Temperature())

    tasks = [
        aiocoap.Context.create_server_context(root, bind=('::', 5683)),
        aiocoap.Context.create_server_context(root, bind=('::', 5684)),  # Add more contexts as needed
    ]

    # Run until all server contexts are closed
    await asyncio.gather(*tasks)

    # Run forever
    # await asyncio.get_running_loop().create_future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"Error: {e}")
