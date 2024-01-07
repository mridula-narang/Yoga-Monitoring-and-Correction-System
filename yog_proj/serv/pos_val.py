import time
from serv.evaluate import Analyze
import json

class posVal:
    def __init__(self,ref) -> None:
        self.l=[(15,13,11),(23,11,13),(24,23,25),(23,25,27),(12,14,16),(24,12,14),(26,24,23),(28,26,24)]
        self.starttime=0
        self.l1={"Elbow":["Left","Right","Fold","Strech","arm"],"Shoulder":["Left","Right","Lower","Raise","arm"],
                 "Hip":["Left","Right","Lower","Lift","leg"],"Knee":["Left","Right","Fold","Strech","Leg"]}
        self.l1key=[["Elbow",0],["Shoulder",0],["Hip",0],["Knee",0],["Elbow",1],["Shoulder",1],["Hip",1],["Knee",1],]
        file_path = r"serv\yog.json"
        with open(file_path, 'r') as json_file:
            self.ref = json.load(json_file)[str(ref)]["ref"]

        self.correct=0  #keep track of the concurrent corrects

    def operation(self,keyjointdata):
        self.obj=Analyze()
        self.lisang=self.obj.extract(eval(keyjointdata["keyjointdat"]),0)
        self.comment()
        return self.comm

    def comment(self):
        self.comm={"Part":[[0,0],[0,0]],"Comment":"","Status":0}
        for i in range(len(self.lisang)):
            a=self.lisang[i][0]                        
            b=self.ref[i]
            c=self.l1key[i]                         #c= ["Elbow",0]     when i=0
            d=self.l1[c[0]]                         #d= ["Left","Right","Fold","Strech","arm"]
            diff=(a-b+360/2)%360-360/2
            if not abs(diff)<=30:
                self.correct=0
                self.starttime=0
                self.comm["Part"][0][0]=self.l[i][0] if self.l[i][0]<self.l[i][1] else self.l[i][1]
                self.comm["Part"][0][1]=self.l[i][1] if self.l[i][0]<self.l[i][1] else self.l[i][0]
                self.comm["Part"][1][0]=self.l[i][1] if self.l[i][1]<self.l[i][2] else self.l[i][2]
                self.comm["Part"][1][1]=self.l[i][2] if self.l[i][1]<self.l[i][2] else self.l[i][1]
                if b<=180:
                    if a<=180:
                        if a>b:
                            self.comm["Comment"]="" + d[2] + " your " + d[c[1]] + " " + d[4] + "" 
                            return
                        if a<b:
                            self.comm["Comment"]="" + d[3] + " your " + d[c[1]] + " " + d[4] + ""
                            return
                    else:
                        if a>b:
                            self.comm["Comment"]="" + d[3] + " your " + d[c[1]] + " " + d[4] + "" 
                            return
                        if a<b:
                            self.comm["Comment"]="" + d[2] + " your " + d[c[1]] + " " + d[4] + ""
                            return
                else:
                    if a<=180:
                        if a>b:
                            self.comm["Comment"]="" + d[3] + " your " + d[c[1]] + " " + d[4] + "" 
                            return
                        if a<b:
                            self.comm["Comment"]="" + d[2] + " your " + d[c[1]] + " " + d[4] + ""
                            return
                    else:
                        if a>b:
                            self.comm["Comment"]="" + d[2] + " your " + d[c[1]] + " " + d[4] + "" 
                            return
                        if a<b:
                            self.comm["Comment"]="" + d[3] + " your " + d[c[1]] + " " + d[4] + ""
                            return
        self.correct+=1
        #if correct = 1 start recording time else let take the previous, this might be 0 or the recorded time
        self.starttime = time.time() if self.correct==1 else self.starttime
        self.comm["Comment"]="Maintain same position"
        self.comm["Status"]=1 if int(time.time()-self.starttime)>=5 else 0
        return