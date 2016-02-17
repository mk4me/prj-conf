# Skrypt instaluje wszystkie potrzebne rzeczy do skompilowania i uruchomienia MDE na Linuxie
# należy skopiować skrypty MdeLinuxStarter.sh i StarterApps.sh do folderu domowego, nadac prawa do uruchomienia i uruchomić
# chmod +x MdeLinuxStarter.sh
# ./MdeLinuxStarter
# Skrypt zapyta o hasło roota w celu instalacji aplikacji
# Instalacja przebiega bez ingerencji uzytkownika, nalezy tylko wypelnic zmienne nizej

assembla_user=""
assembla_pass=""


ftp_adress="83.230.112.91/lib/MDE/"
ftp_user=""
ftp_pass=""

sudo sh ./StarterApps.sh

mkdir ~/programming
mkdir ~/programming/Work
mkdir ~/programming/Work/MDE
mkdir ~/programming/Work/MDE/_out
mkdir ~/programming/Work/MDE/MDE
mkdir ~/programming/Work/MDE/Libs

if [ -z "$assembla_user"] || [ -z "$assembla_pass" ]; then 
svn checkout https://subversion.assembla.com/svn/edytor/ ~/programming/Work/MDE/MDE 
else  
svn checkout --non-interactive --no-auth-cache --username $assembla_user --password $assembla_pass https://subversion.assembla.com/svn/edytor/ ~/programming/Work/MDE/MDE 
fi

file=`ncftpls -m ftp://$ftp_user:$ftp_pass@$ftp_adress  | grep linux64 | sort -k1 | awk '{ print $2 }' | tail -n1`
#echo "~/programming/Work/MDE/Libs/$file"
ncftpget ftp://$ftp_user:$ftp_pass@$ftp_adress$file 
mv $file ~/programming/Work/MDE/Libs/$file
7z x ~/programming/Work/MDE/Libs/$file -o./programming/Work/MDE/Libs/"${file%%.*}/"

ln -s ~/programming/Work/MDE/Libs/${file%%.*}/include ~/programming/Work/MDE/MDE/trunk/include
ln -s ~/programming/Work/MDE/Libs/${file%%.*}/lib     ~/programming/Work/MDE/MDE/trunk/lib

