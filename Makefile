run_mini_project_2:
	./scripts/mini_project2.sh

status:
	./scripts/status.sh

tap:
	./scripts/gnrc_border_router_tap.sh

broker:
	./scripts/mqtt_broker_setup.sh

mqtt:
	./scripts/emcute_mqttsn.sh

run_sensor:
	./scripts/sensor_read_experiment.sh

.PHONY: border_router

border_router:
	./scripts/gnrc_border_router.sh

sense:
	./scripts/sensor-connected.sh

.PHONY: stop

stop:
	./scripts/stoppers/stop_all.sh $(filter-out $@,$(MAKECMDGOALS))

stop_one:
	iotlab-experiment stop

test_coap_server:
	aiocoap-client coap://[2001:660:5307:3107:a4a9:dc28:5c45:38a9]/riot/board iotlab-m3

# run border router and network node, you get a shell to the network node where you can ping public ipv6 addresses
ping_to_google:
	./scripts/ping_to_google.sh

# run border router node
gnrc_border_router:
	./scripts/gnrc_border_router.sh

sensor2:
	./scripts/sensor2.sh

# run border router and coap server in the same network
coap_server:
	./scripts/coap_server.sh

# run coap_server in separate shell
coap_test:
	./scripts/coap_test.sh

# Current test carried out after running coap_server in separate shell
coap_client_test:
	./scripts/coap_client_test.sh

# same as about shortenned work for faster dev
coap:
	./scripts/coap_client_test.sh

clean_all: clean
	./scripts/clean_all.sh

clean:
	find ./src -type d -name bin -exec rm -rf {} +
	rm -Rf bin
	rm -Rf ~/shared/logs
	rm ~/shared/*.elf
	rm ~/A8/*.elf

broker_sub:
	./scripts/broker_sub.sh

sub_dead_sensors:
	./scripts/broker_sub_dead_sensors.sh

sub_sensor1:
	./scripts/broker_sub_sensor1.sh

sub_sensor2:
	./scripts/broker_sub_sensor2.sh

sub_sensor3:
	./scripts/broker_sub_sensor3.sh

broker_pub:
	./scripts/broker_pub.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@: