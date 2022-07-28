######################################
# Histogram vs PDF visualization
######################################

import numpy as n
import pandas as pd


import matplotlib.pyplot as plt
import seaborn as sns


df_train = pd.read_csv('titanic_train.csv')
df_test = pd.read_csv('titanic_test.csv')


fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18,4))

sns.distplot(df_train['Age'].dropna(), ax=ax1)
ax1.set_title('Train set')

sns.distplot(df_test['Age'].dropna(), ax=ax2)
ax2.set_title('Test set')