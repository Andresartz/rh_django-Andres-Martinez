from rest_framework import serializers
from .models import Empleado


class EmpleadoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empleado
        fields = '__all__'

    def validate_sueldo(self, value):
        if value < 0:
            raise serializers.ValidationError("El sueldo no puede ser negativo.")
        return value
