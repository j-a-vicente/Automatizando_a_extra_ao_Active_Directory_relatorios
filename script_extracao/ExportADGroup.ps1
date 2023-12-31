﻿# Este script foi criado para extrair os GROUP e suas informações do Active Directory e inserir elas 
# em um servido de banco dados para futuro tratamento.
# O script foi criado para ser executado de dentro de um JOB do agent do SQL Server.

#Variáveis do servido e banco de dados
$SQLInstance = "XXXXXXXX"
$SQLDatabase = "XXXXXXXX"

#Parametro necessário para execução do script dentro do job
Set-Location C:


# Limpeza da tabela de STAGE que reseberá os dados brutos
 $SQLQueryDelete = "USE $SQLDatabase
    TRUNCATE TABLE [brz].[group]"

$SQLQuery1Output = Invoke-Sqlcmd -query $SQLQueryDelete -ServerInstance $SQLInstance


#======= ATENÇÃO ========#
# Devido o volume de usuários ser muito grande foi criado um loop para diminuir o volume por insert

# Variável que vai receber os valores para pesquisa
$Iniciais = 'a*','b*','c*','d*','e*','g*','h*',
'i0*','i1*','i2*','i3*','i4*','i5*''i6*','i7*','i8*','i9*',
'j*','k*','l*','m*','n*','o*','p*','q*','r*',
's_*','s0*','s1*','s2*','s3*','s4*','s5*','s6*','s7*','s8*','s9*',
't*','u*','x*','z*','w*',
'1*','2*','3*','4*','5*','6*','7*','8*','9*','0*'



#Loop das iniciais
ForEach($Inicial in $Iniciais){


#Iniciar a extração dos Usuários do Active Directory
# A variável "$Usrs" é uma matriz que receberá o resultado do comando de extração dos usuários.

try{
 $Usrs = Get-ADGroup -f {SamAccountName -like $Inicial} -Properties * | Select-Object SID,Name,DisplayName,SamAccountName,Description,CanonicalName,DistinguishedName,
    GroupCategory, Member, MemberOf, GroupScope,ObjectClass,
    ProtectedFromAccidentalDeletion,
    @{Name='Created';Expression={$_.Created.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='Deleted';Expression={$_.Deleted.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='Modified';Expression={$_.Modified.ToString("yyyy\/MM\/dd HH:mm:ss")}}  -ErrorAction stop
}catch{
Write-Output $Inicial
throw $_
break
}



#Loop que será usuado para transferir os dados da matriz para o banco de dados
 ForEach($Usr in $Usrs){
 
 #Para cada linha que a matriz percorre e inserido o valor na variável de destino.
	$SID = $Usr.SID


    if ($Usr.Name){      
        $Lipemza = $Usr.Name         
        $Name = $Lipemza.replace("'","")	 
    }else{$Name = $Usr.Name}


    if ($Usr.DisplayName){      
        $Lipemza = $Usr.DisplayName
	    $DisplayName = $Lipemza.replace("'","")
    }else{$DisplayName = $Usr.DisplayName}


    if ($Usr.SamAccountName){      
        $Lipemza = $Usr.SamAccountName
	    $SamAccountName = $Lipemza.replace("'","")
    }else{$DisplayName = $Usr.SamAccountName}


    if ($Usr.Description){      
        $Lipemza = $Usr.Description
	    $Description = $Lipemza.replace("'","")
    }else{$Description = $Usr.Description}	


    if ($Usr.CanonicalName){      
        $Lipemza = $Usr.CanonicalName
	    $CanonicalName = $Lipemza.replace("'","")
    }else{$Description = $Usr.CanonicalName}	


    if ($Usr.DistinguishedName){      
        $Lipemza = $Usr.DistinguishedName
	    $DistinguishedName = $Lipemza.replace("'","")
    }else{$Office = $Usr.DistinguishedName}


	$GroupCategory = $Usr.GroupCategory

    if ($Usr.member){      
        $Lipemza = $Usr.member
	    $member = $Lipemza.replace("'","")
    }else{$member = $Usr.member}

    if ($Usr.MemberOf){      
        $Lipemza = $Usr.MemberOf
	    $MemberOf = $Lipemza.replace("'","")
    }else{$MemberOf = $Usr.MemberOf}


	$GroupScope = $Usr.GroupScope
	$ObjectClass = $Usr.ObjectClass
	$ProtectedFromAccidentalDeletion = $Usr.ProtectedFromAccidentalDeletion
    $Created = $Usr.Created
	$Deleted = $Usr.Deleted
	$Modified = $Usr.Modified


#A variável "$SQLQuery" receberar o insert com os dados para ser executado no banco
$SQLQuery = "USE $SQLDatabase
INSERT INTO [brz].[group]
           ([SID],[Name],[DisplayName],[SamAccountName],[Description]
           ,[CanonicalName],[DistinguishedName],[GroupCategory],[Member],[MemberOf]
           ,[GroupScope],[ObjectClass],[ProtectedFromAccidentalDeletion]
           ,[Created],[Deleted],[Modified])
VALUES ('$SID','$Name','$DisplayName','$SamAccountName','$Description',
        '$CanonicalName','$DistinguishedName','$GroupCategory','$member','$MemberOf',
        '$GroupScope','$ObjectClass','$ProtectedFromAccidentalDeletion',
        '$Created','$Deleted','$Modified');"


#Executa o comando de insert com os dados
try{
    $SQLQuery1Output = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance -ErrorAction stop
}catch{
Write-Output $SQLQuery
throw $_
break
}
#Fim do loop da matriz com os usuário
}
#A matriz "$Usrs e limpada para reseber novos dados.
$Usrs.clear
}#fim do loop das legras