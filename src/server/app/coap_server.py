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
        logger.debug(f"\nReceived message: {payload}")

        decodedValue = await decodeTemperature(payload['site'], payload['value'], payload['sensor'])
        logger.debug(f"Decoded values: {decodedValue}")

        if decodedValue != None:
            recordedFlag = await sendInfluxdb(decodedValue, payload['site'], payload['sensor'])
            logger.debug(f"Recorded flag: {recordedFlag}\n")

        return aiocoap.Message(content_format=0,
                payload=json.dumps({"status": "OK"}).encode('utf8'))

async def handle_requests():
    root = resource.Site()
    root.add_resource(['time'], TimeResource())
    root.add_resource(['temp'], Temperature())

    context = await aiocoap.Context.create_server_context(root, bind=('::', 5683))
    logger.info("Server started on ('::', 5683)")

    try:
        while True:
            await asyncio.sleep(3600)  # Sleep for 1 hour or adjust as needed
    except asyncio.CancelledError:
        pass
    finally:
        await context.shutdown()

async def main():
    await asyncio.gather(handle_requests())

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"Error: {e}")
