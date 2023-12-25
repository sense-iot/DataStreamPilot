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

# run border router and network node, you get a shell to the network node where you can ping public ipv6 addresses
ping_to_google:
	./scripts/ping_to_google.sh

# run border router node
gnrc_border_router:
	./scripts/gnrc_border_router.sh

sensor2:
	./scripts/sensor2.sh


coap:
	./scripts/coap_testing.sh

	coap:
	./scripts/coap_testing.sh


clean_all: clean
	./scripts/clean_all.sh

clean:
	find ./src -type d -name bin -exec rm -rf {} +
	rm -Rf bin
	rm -Rf ~/shared/logs
	rm -f ~/A8/*.elf
	rm -f ~/A8/*.txt
	rm -f ~/A8/*.conf
	rm -f ~/shared/*.elf
	rm -f ~/shared/*.txt
	rm -f ~/shared/*.conf
	

broker_sub:
	./scripts/broker_sub.sh

sub_dead_sensors:
	./scripts/broker_sub_dead_sensors.sh

sub_sensor1:
	./scripts/broker_sub_sensor1.sh

sub_sensor1_2:
	./scripts/broker_sub_sensor1_2.sh

sub_sensor2:
	./scripts/broker_sub_sensor2.sh

sub_sensor2_2:
	./scripts/broker_sub_sensor2_2.sh

sub_sensor3:
	./scripts/broker_sub_sensor3.sh

sub_sensor3_2:
	./scripts/broker_sub_sensor3_2.sh

broker_pub:
	./scripts/broker_pub.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@: