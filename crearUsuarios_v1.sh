#!/usr/bin/env bash
echo "Bienvenido al script de creacion de usuarios"
echo "Introduzca a continuacion los parametros solicitados"
echo "ID de usuario"
read -r id
if sudo cat /etc/passwd | tail | cut -d ":" -f 1 | grep "$id"; then
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
	sudo cat /etc/group | tail | grep "1000*" | cut -d ":" -f 1
	read -r grup	
elif [[ "$opcion" == "c" ]]; then
	echo "Escriba el nombre del grupo"
	read -r grup
	if sudo cat /etc/group | tail | cut -d ":" -f 1 | grep "$grup"; then
		echo "EL grupo ya existe"
		exit 1;
	fi
	echo "Creando grupo.."
	sudo groupadd "$grup"
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
sudo useradd -c "$com" -m -d "$home" -g "$grup" -s "$shell" "$id"
echo "Usuario creado con exito"

while true; do
	echo "Establezca una contraseña para el usuario $id"
	echo "Debe tener un tamaño minimo de 12 caracteres, incluyendo 
	mayusculas, minusculas y numeros"
	read -r -s pass

	if [[ ${#pass} -ge 12 && "$pass" =~ [A-Z] && "$pass" =~ [a-z] && "$pass" =~ [0-9] ]]; then
		echo "$id" "$pass" >> .secreto_noabrir.txt
		echo "$id:$pass" | sudo chpasswd
		echo "Contraseña establecida"
		break
	else
		echo "Error: La contraseña no cumple con los parametros especificados"
	fi
done

echo "¿Desea establecer una cuota en el disco  para el usuario?"
echo "y o n"
read -r respuesta
if [[ "$respuesta" == "y" ]]; then
	echo "Tamaño en MB de la cuota soft:"
	read -r soft
	echo "Tamaño en MB de la cuota hard:"
	read -r hard

	if [[ ! "$soft" =~ ^[0-9]+$ || ! "$hard" =~ ^[0-9]+$ ]]; then
		echo "Formato no valido"
		exit 1
	fi
	bloque_s=$((soft * 2048))
	bloque_h=$((hard * 2048))
	
	echo "Estableciendo cuota..."
	sudo setquota -u "$id" "$bloque_s" "$bloque_h" 0 0 /home
	echo "Cuota establecida. Avise al usuario sobre su limite hard y soft"
fi
