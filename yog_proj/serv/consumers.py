import json
from channels.generic.websocket import WebsocketConsumer
from serv.evaluate import Analyze
from serv.act_val import actVal
from serv.pos_val import posVal
import time

class YogConsumer(WebsocketConsumer):
    count=0
        
    def connect(self):
        self.accept()
        self.pstep=0
        self.astep=0
        
    def disconnect(self, close_code):
        pass

    def receive(self, text_data):
        result={}
    
        keyjointdata=eval(text_data)
        
        if keyjointdata["monitor"]=="posture":
            if(self.pstep!=keyjointdata['step']):
                self.val=posVal(keyjointdata['step'])
                self.pstep=keyjointdata['step']

            result=self.val.operation(keyjointdata)
            result['r_step']=keyjointdata['step']

        else:
            if(self.astep!=keyjointdata['step']):
                self.val=actVal(keyjointdata['step'])
                self.astep=keyjointdata['step']
                
            result=self.val.operation(keyjointdata)
            # result={}
            # result['Status']=1
            result['r_step']=keyjointdata['step']
            
            # time.sleep(3)
                    
        self.send(json.dumps({
            'message': result
        }))
        self.count+=1