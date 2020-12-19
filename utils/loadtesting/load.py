import time
from datetime import datetime
from locust import HttpUser, task, between, constant, events

_file = open('stats.csv', 'w')

class QuickstartUser(HttpUser):
#   wait_time = between(1, 1)
   wait_time = constant(0)
#    base_url = "http://172.16.16.111:30553"

#    @task
#    def index_page(self):
#        self.client.get("/s1")

#   @events.init.add_listener
#   def init(environment, **kw):
#      events.request_success += self.hook_request_success
   
   @events.quitting.add_listener
   def quitting(environment):
      _file.close()

   @events.request_success.add_listener
   def request_success(request_type, name, response_time, response_length, **kw):
        _file.write(datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3] + ";" + request_type + ";" + name + ";" + str(response_time) + ";" + str(response_length) + "\n")

   @task(3)
   def view_cpu_workload(self):
      #for workload_size in range(10):
      self.client.get(f"/s1/cpu/100", name="/s1/cpu")
         #time.sleep(1)

#    def on_start(self):
#        a=1
