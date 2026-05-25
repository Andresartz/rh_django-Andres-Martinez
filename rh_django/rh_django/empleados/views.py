from rest_framework import generics
from .models import Empleado
from .serializers import EmpleadoSerializer


class EmpleadoListCreateView(generics.ListCreateAPIView):
    """GET /api/empleados/  →  lista todos los empleados
       POST /api/empleados/ →  crea un empleado nuevo"""
    queryset = Empleado.objects.all()
    serializer_class = EmpleadoSerializer


class EmpleadoRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    """GET    /api/empleados/<id>/ → obtiene un empleado
       PUT    /api/empleados/<id>/ → actualiza completo
       PATCH  /api/empleados/<id>/ → actualiza parcial
       DELETE /api/empleados/<id>/ → elimina"""
    queryset = Empleado.objects.all()
    serializer_class = EmpleadoSerializer
    lookup_field = 'idEmpleado'
