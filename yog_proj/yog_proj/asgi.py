"""
ASGI config for yog_proj project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/4.2/howto/deployment/asgi/
"""

import os

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from yog_proj import urls

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'yog_proj.settings')

application = ProtocolTypeRouter({
    "http" : get_asgi_application(),
    
    'websocket': URLRouter(urls.websocket_urlpatterns),
})
