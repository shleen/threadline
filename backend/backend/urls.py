"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path

from apps.core import views

urlpatterns = [
    path('clothing/create', views.create_clothing),
    path('closet/get', views.get_closet),
    path('recommendation/get', views.get_recommendations),
    path('outfits/get', views.get_prev_outfits),
    path('outfit/post', views.log_outfit),
    path('utilization/get', views.get_utilization),
    path('background/remove', views.remove_background),
    path('image/process', views.process_image),
    path('categories/get', views.get_categories),
    path('declutter/get', views.get_declutter),
    path('declutter/post', views.post_declutter)
]
