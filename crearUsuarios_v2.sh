#!/usr/bin/env bash
echo "Bienvenido al script de creacion de usuarios"
echo "Introduzca a continuacion los parametros solicitados"
echo "ID de usuario"
read -r id
if cat  /etc/passwd | tail | cut -d ":" -f 1 | grep "$id"; then
	echo "EL usuario ya existe"
	exit 1;
fi
echo "Grupo donde pertenecera el usuario"
echo "Puede agregarlo a algun grupo existente o crear un nuevo grupo"
echo "a = agregar, c = crear"
read -r opcion

if [[ "$opcion" != "a" && "$opcion" != "c" ]]; then 
	echo "Valor no valido"
	exit 1
fi

if [[ "$opcion" == "a" ]]; then
	echo "Escriba el grupo para agregar"
	cat /etc/group | tail | grep "1000*" | cut -d ":" -f 1
	read -r grup	
elif [[ "$opcion" == "c" ]]; then
	echo "Escriba el nombre del grupo"
	read -r grup
	if cat /etc/group | tail | cut -d ":" -f 1 | grep "$grup"; then
		echo "EL grupo ya existe"
		exit 1;
	fi
	echo "Creando grupo.."
	groupadd "$grup"
fi

echo "Home donde trabajara el usuario"
read -r home
echo "Nombre completo del usuario o comentario"
read -r com
echo "Shell con el que trabajara el usuario"
read -r shell

test "$id" || { echo "Error: no se pudo crear usuario falta el parametro ID de usuario "; exit 1;}
test "$home" || { echo "Error: no se pudo crear usuario falta el parametro Home"; exit 1;}
test "$grup" || { echo "Error: no se pudo crear usuario falta el parametro Grupo"; exit 1;}


echo "Creando usuario..."
useradd -c "$com" -m -d "$home" -g "$grup" -s "$shell" "$id"
echo "Usuario creado con exito"

while true; do
	echo "Establezca una contraseña para el usuario $id"
	echo "Debe tener un tamaño minimo de 12 caracteres, incluyendo 
	mayusculas, minusculas y numeros"
	read -r -s pass

	if [[ ${#pass} -ge 12 && "$pass" =~ [A-Z] && "$pass" =~ [a-z] && "$pass" =~ [0-9] ]]; then
		echo "$id" "$pass" >> .secreto_noabrir.txt
		echo "$id:$pass" | chpasswd
		echo "Contraseña establecida"
		break
	else
		echo "Error: La contraseña no cumple con los parametros especificados"
	fi
done

echo "¿Desea establecer una cuota en el disco  para el usuario?"
echo "y/n"
read -r respuesta

if [[ "$respuesta" != "y" &&  "$respuesta" != "n" ]]; then
	echo "Opcion invalida"
	exit 1
fi

if [[ "$respuesta" == "y" ]]; then
	echo "Tamaño del limite soft:"
	read -r soft
	echo "Tamaño del limite  hard:"
	read -r hard

	if [[ ! "$soft" =~ ^[0-9]+$ || ! "$hard" =~ ^[0-9]+$ ]]; then
		echo "Formato no valido"
		exit 1
	fi
	
	echo "Estableciendo cuota..."
	setquota -u "$id" "$soft" "$hard" 0 0 /
	echo "Cuota establecida. Avise al usuario sobre su limite hard y soft"
fi

echo "¿Desea que el usuario puedar ejecutar comandos con sudo?"
echo "y/n"
read -r opcion

if [[ "$opcion" != "y" && "$opcion" != "n" ]]; then
	echo "Opcion invalida"
	exit 1
fi

if [[ "$opcion" == "y" ]]; then
	echo "¿Que tipo comandos puede ejecutar el usuario?"
	select opt in "todos los comandos" "solo comandos especificos" ; do
		if [ "$opt" = "todos los comandos" ]; then
			echo "Estableciendo permisos..."
			echo "$id ALL=(ALL:ALL) ALL" | EDITOR='tee -a' visudo
			echo "Permisos establecidos"
			exit
		elif [ "$opt" = "solo comandos especificos" ]; then
			echo "Seleccione el que tipo de comandos puede ejecutar"
			select opt2 in "Manejo de usuarios" "Configuracion de red" "actualizar e instalar paquetes" ; do
				if [ "$opt2" = "Manejo de usuarios" ]; then
					echo "Estableciendo permisos..."
					"$id ALL= /usr/sbin/useradd, /usr/bin/passwd, /usr/sbin/groupadd, /usr/sbin/userdel, /usr/sbin/groupdel" | sudo EDITOR='tee -a' visudo
					echo "Permisos establecidos"
					exit
				elif [ "$opt2" = "Configuracion de red" ]; then
					echo "Estableciendo permisos..."
					"$id ALL= /sbin/ifconfig, /sbin/ip, /usr/bin/nmcli" | sudo EDITOR='tee -a' visudo
					echo "Permisos establecidos"
					exit
				elif [ "$opt2" = "Actualizar e instalar paquetes" ]; then
					echo "Estableciendo permisos..."
					"$id ALL=  /usr/bin/apt, /usr/bin/dpkg" | sudo EDITOR='tee -a' visudo
					echo "Permisos establecidos"
					exit
				fi
			done
		fi
	done
fi
