import concurrent.futures
import math
import time

class Analyze:

    def __init__(self):
        self.lisang=[[],[],[],[],[],[],[],[]]
        self.l=[(15,13,11),(23,11,13),(24,23,25),(23,25,27),(12,14,16),(24,12,14),(26,24,23),(28,26,24)]

    def extract(self,keyjointdata,ind):
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            a13 = executor.submit(self.calc,keyjointdata[self.l[0][0]][ind],keyjointdata[self.l[0][1]][ind],
            keyjointdata[self.l[0][2]][ind],0)
            a11 = executor.submit(self.calc,keyjointdata[self.l[1][0]][ind],keyjointdata[self.l[1][1]][ind],
            keyjointdata[self.l[1][2]][ind],1)
            a23 = executor.submit(self.calc,keyjointdata[self.l[2][0]][ind],keyjointdata[self.l[2][1]][ind],
            keyjointdata[self.l[2][2]][ind],2)
            a25 = executor.submit(self.calc,keyjointdata[self.l[3][0]][ind],keyjointdata[self.l[3][1]][ind],
            keyjointdata[self.l[3][2]][ind],3)
            a14 = executor.submit(self.calc,keyjointdata[self.l[4][0]][ind],keyjointdata[self.l[4][1]][ind],
            keyjointdata[self.l[4][2]][ind],4)
            a12 = executor.submit(self.calc,keyjointdata[self.l[5][0]][ind],keyjointdata[self.l[5][1]][ind],
            keyjointdata[self.l[5][2]][ind],5)
            a24 = executor.submit(self.calc,keyjointdata[self.l[6][0]][ind],keyjointdata[self.l[6][1]][ind],
            keyjointdata[self.l[6][2]][ind],6)
            a26 = executor.submit(self.calc,keyjointdata[self.l[7][0]][ind],keyjointdata[self.l[7][1]][ind],
            keyjointdata[self.l[7][2]][ind],7)
            concurrent.futures.wait([a14,a12,a24,a26,a13,a11,a23,a25])
        return self.lisang

    def calc(self,a,b,c,index):
        d=math.atan2((c[1]-b[1]),(c[0]-b[0]))-math.atan2((a[1]-b[1]),(a[0]-b[0]))
        deg=(180*d)/math.pi
        degree=None
        if deg<=0:
            degree=abs(deg)
        else:
            degree=(270-deg)+90
        
        if len(self.lisang[index])==0 or abs(degree-self.lisang[index][-1])>1:
            self.lisang[index].append(degree)