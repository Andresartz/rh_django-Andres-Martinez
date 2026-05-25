from django.urls import path
from .views import EmpleadoListCreateView, EmpleadoRetrieveUpdateDestroyView

urlpatterns = [
    path('empleados/', EmpleadoListCreateView.as_view(), name='empleado-list-create'),
    path('empleados/<int:idEmpleado>/', EmpleadoRetrieveUpdateDestroyView.as_view(), name='empleado-detail'),
]
