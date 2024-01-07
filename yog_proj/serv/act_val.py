import json
from serv.evaluate import Analyze
import numpy as np
from tslearn.metrics import dtw_path, cdist_dtw
import matplotlib.pyplot as plt


class actVal:
    def __init__(self,ref) -> None:
        self.l1={"Elbow":["Left","Right","Fold","Strech","arm"],"Shoulder":["Left","Right","Lower","Raise","arm"],
                 "Hip":["Left","Right","Lift","Lower","leg"],"Knee":["Left","Right","Fold","Strech","Leg"]}
        self.l1key=[["Elbow",0],["Shoulder",0],["Hip",0],["Knee",0],["Elbow",1],["Shoulder",1],["Hip",1],["Knee",1],]
        file_path = r"serv\yog.json"
        with open(file_path, 'r') as json_file:
            a = json.load(json_file)
            self.lisang = a[str(ref)]["keyjoint"]
            self.threshold = a[str(ref)]["thresh"]
            
    def operation(self,keyjointdata):
        self.count=0
        self.obj=Analyze()
        # print(len(eval(keyjointdata['keyjointdat'])[0]))
        for i in range(7,len(eval(keyjointdata['keyjointdat'])[0])):
            self.obj.extract(eval(keyjointdata['keyjointdat']),i)
        self.lisang1=self.obj.lisang

        self.DTW()
        return self.comm
    
    def DTW(self):
        self.comm={"Status":0}
        angle_result=[]
        
        fig,axes=plt.subplots(4,2, sharey=True,figsize=(10,50))
        fig.subplots_adjust(hspace=0.7, wspace=0.3)

        for i in range(len(self.lisang)):
            # Example time-series angle data (replace with your actual data)
            mentor_angles = self.lisang[i]  # List of angles
            user_angles = self.lisang1[i]    # List of angles

            # Convert lists to numpy arrays as 0-dimensional arrays
            mentor_angles = np.array(mentor_angles)
            user_angles = np.array(user_angles)

            # Set Sakoe-Chiba band width as a percentage of the sequence length
            band_width = 0.5  # Adjust as needed

            # Calculate DTW alignment path
            alignment_path = dtw_path(mentor_angles, user_angles, sakoe_chiba_radius=int(band_width * max(len(mentor_angles),
                                                                                                           len(user_angles))))

            # Calculate DTW distances between aligned points
            aligned_distances = [cdist_dtw(np.array([mentor_angles[i]]), np.array([user_angles[j]])) for i, j in alignment_path[0]]

            # Set a similarity threshold (adjust as needed)
            similarity_threshold = self.threshold[i]
            # print(similarity_threshold)

            # Identify segments with deviations
            deviation_indices = [i for i, distance in enumerate(aligned_distances) if distance[0] > similarity_threshold]
            
            # Plot mentor and user angles
            axes[i//2][i%2].plot(range(len(user_angles)), user_angles, label='User Angles')
            axes[i//2][i%2].plot(range(len(mentor_angles)), mentor_angles, label='Mentor Angles')

            axes[i//2][i%2].set_title(f"plot for {self.l1[self.l1key[i][0]][self.l1key[i][1]]} {self.l1key[i][0]}")

            for k,(l, j) in enumerate(alignment_path[0]):
                if aligned_distances[k][0] > similarity_threshold:
                    axes[i//2][i%2].plot(j, user_angles[j],'ro', markersize=8, markerfacecolor='none', markeredgecolor='red')
                    
            # for l, j in alignment_path[0]:
            #     if aligned_distances[l][0] > similarity_threshold:
            #         axes[i//2][i%2].plot([l, j], [mentor_angles[l], user_angles[j]], 'r--', linewidth=1)
            #     else:
            #         axes[i//2][i%2].plot([l, j], [mentor_angles[l], user_angles[j]], 'k--', linewidth=1)
    
            # print(deviation_indices)

            cons=0
            count=0
            if len(deviation_indices)==0:
                angle_result.append(0)
            else:
                for k in range(len(deviation_indices)-1):
                    if deviation_indices[k] == deviation_indices[k+1]-1:
                        cons+=1
                        if cons==3:
                            count+=1
                            self.count+=1
                    else:
                        cons=0
                angle_result.append(count)
        self.comm["Status"]=1 if self.count==0 else 0
        print("angle: ",angle_result)
        print(self.count)
        plt.legend()
        plt.show()
        