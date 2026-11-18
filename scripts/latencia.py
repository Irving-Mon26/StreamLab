"""Calcula con cinco mediciones reales; consulta --help para los parámetros."""
import argparse, statistics
p=argparse.ArgumentParser(description='Media, desviación muestral y transferencia de tres escenarios independientes.')
p.add_argument('segundos',nargs=5,type=float)
p.add_argument('--bitrate',type=float,required=True,help='Kbps totales reales: video + audio')
p.add_argument('--tarifa',type=float,required=True,help='USD/GB del primer tramo, verificados en tu región')
p.add_argument('--franquicia',type=float,default=0,help='GB gratuitos RESTANTES en la cuenta')
p.add_argument('--limite-tramo',type=float,default=10240,help='GB facturables en el primer tramo; verificar en AWS')
p.add_argument('--tarifa-siguiente',type=float,help='USD/GB del segundo tramo; obligatoria si se supera el primero')
a=p.parse_args()
if min(a.segundos)<0 or min(a.bitrate,a.tarifa,a.franquicia,a.limite_tramo)<0 or a.tarifa_siguiente is not None and a.tarifa_siguiente<0: p.error('No uses valores negativos')
print(f'Media: {statistics.mean(a.segundos):.2f} s')
print(f'Desviación estándar muestral: {statistics.stdev(a.segundos):.2f} s')
for n in [50,500,5000]:
 gb=a.bitrate*1000*7200*n/8/1e9
 billed=max(0,gb-a.franquicia)
 if billed>a.limite_tramo and a.tarifa_siguiente is None:
  cost='PENDIENTE: agrega --tarifa-siguiente con el precio verificado'
 else:
  usd=min(billed,a.limite_tramo)*a.tarifa+max(0,billed-a.limite_tramo)*(a.tarifa_siguiente or 0)
  cost=f'{usd:.2f} USD'
 print(f'{n} espectadores, 2 horas: {gb:.2f} GB; transferencia estimada: {cost}')
print('Escenarios independientes. Dos tramos como máximo; si aplican más, usa la calculadora oficial.')
print('No incluye EC2, IPv4, EBS, impuestos ni sobrecarga HTTP/HLS. No es tu factura final.')
