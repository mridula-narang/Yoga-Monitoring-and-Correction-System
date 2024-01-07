from django.db import models

class Data(models.Model):
    # Define your fields here
    x = models.IntegerField()
    y = models.IntegerField()
    landmark=models.CharField(max_length=100)
