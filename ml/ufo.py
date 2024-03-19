#!/usr/bin/env python3
"""
NOTE: ACG does not let us use any SageMaker resources, so had to go to scikit-learn
for this one.  
"""

# %%
# Imports
import folium
import pandas as pd
import seaborn as sns
from IPython.display import display
from sklearn.cluster import KMeans

# %%
# Read data
df = pd.read_csv('ufo_fullset.csv')
display(df.head())
X = df[['latitude', 'longitude']].values
display(X)
print(X.dtype)

# %%
# Implement kmeans clustering algorithm
kmeans = KMeans(n_clusters=10, random_state=42).fit(X)
kmeans.cluster_centers_

# %%
# Generate plot

# Generate a color palette with 10 colors
colors = sns.color_palette('husl', 10).as_hex()

# Initialize the map at a central point
plotted_map = folium.Map(location=[0, 0], zoom_start=1)

# Plot each point in the dataset
for coord, label in zip(X, kmeans.labels_):
    folium.Circle(
        location=coord,
        radius=100000,  # Radius in meters
        color=None,  # Border color
        fill=True,
        fill_color=colors[label],  # Use the label to assign a color
        fill_opacity=0.5,
        popup=f'Label: {label}',  # Popup label
    ).add_to(plotted_map)

# Plot the KMeans centers with larger, red circles
for center, label in zip(kmeans.cluster_centers_, list(range(10))):
    folium.Circle(
        location=center,
        radius=200000,  # Radius in meters
        color='black',  # Border color
        fill=True,
        fill_color=colors[label],  # Center color
        fill_opacity=1,
        popup=f'Center for Label: {label}',  # Popup label
    ).add_to(plotted_map)

plotted_map

