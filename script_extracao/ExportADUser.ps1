﻿# Este script foi criado para extrair os USER e suas informações do Active Directory e inserir elas 
# em um servido de banco dados para futuro tratamento.
# O script foi criado para ser executado de dentro de um JOB do agent do SQL Server.

#Variáveis do servido e banco de dados
$SQLInstance = "XXXXXXXX"
$SQLDatabase = "XXXXXXXX"

#Parametro necessário para execução do script dentro do job
Set-Location C:


# Limpeza da tabela de STAGE que reseberá os dados brutos
 $SQLQueryDelete = "USE $SQLDatabase
    TRUNCATE TABLE [brz].[user]"

$SQLQuery1Output = Invoke-Sqlcmd -query $SQLQueryDelete -ServerInstance $SQLInstance


#======= ATENÇÃO ========#
# Devido o volume de usuários ser muito grande foi criado um loop para diminuir o volume por insert

# Variável que vai receber os valores para pesquisa
$Iniciais = 'a*','b*','c*','d*','e*','g*','h*',
'i0*','i1*','i2*','i3*','i4*',
#'i505000*','i505001*',
'i50501*','i50502*','i50503*','i50504*','i50505*','i50506*','i50507*','i50508*','i50509*',
'i5051*','i5052*','i5053*','i5054*','i5055*','i5056*','i5057*','i5058*','i5059*',
'i506*','i507*','i508*','i509*',
'i51*','i52*','i53*','i54*','i55*','i56*','i57*','i58*','i59*',
'i501*','i502*','i503*','i504*',
'i6*','i7*','i8*','i9*',
'j*','k*','l*','m*','n*','o*','p*','q*','r*','s*','t*','u*','x*','z*','w*',
'1*','2*','3*','4*','5*','6*','7*','8*','9*','0*'



#Loop das iniciais
ForEach($Inicial in $Iniciais){


#Iniciar a extração dos Usuários do Active Directory
# A variável "$Usrs" é uma matriz que receberá o resultado do comando de extração dos usuários.

try{
 $Usrs = Get-ADUser -f {SamAccountName -like $Inicial} -Properties * | Select-Object SID,Name,DisplayName,SamAccountName,mail,Title,Department,Description,employeeType,Company,
	Office,City,DistinguishedName,MemberOf,
    @{Name='createTimeStamp';Expression={$_.createTimeStamp.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='Deleted';Expression={$_.Deleted.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='Modified';Expression={$_.Modified.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='PasswordLastSet';Expression={$_.PasswordLastSet.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='AccountExpirationDate';Expression={$_.AccountExpirationDate.ToString("yyyy\/MM\/dd HH:mm:ss")}},
	@{Name='msExchWhenMailboxCreated';Expression={$_.msExchWhenMailboxCreated.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    @{Name='LastLogonDate';Expression={$_.LastLogonDate.ToString("yyyy\/MM\/dd HH:mm:ss")}},
    EmailAddress,MobilePhone,msExchRemoteRecipientType,
	ObjectClass,PasswordExpired,PasswordNeverExpires,PasswordNotRequired,Enabled,LockedOut,
	CannotChangePassword,
    userAccountControl  -ErrorAction stop
}catch{
Write-Output $Inicial
throw $_
break
}



#Loop que será usuado para transferir os dados da matriz para o banco de dados
 ForEach($Usr in $Usrs){
 
 #Para cada linha que a matriz percorre e inserido o valor na variável de destino.
	$SID = $Usr.SID
         $Lipemza = $Usr.Name         
         $Name = $Lipemza.replace("'","")	 

       if ($Usr.DisplayName){      
         $Lipemza = $Usr.DisplayName
	     $DisplayName = $Lipemza.replace("'","")
        }else{$DisplayName = $Usr.DisplayName}

	$SamAccountName = $Usr.SamAccountName
	$mail = $Usr.mail
	$Title = $Usr.Title
	$Department = $Usr.Department

       if ($Usr.Description){      
         $Lipemza = $Usr.Description
	     $Description = $Lipemza.replace("'","")
        }else{$Description = $Usr.Description}	

	$employeeType = $Usr.employeeType
	$Company = $Usr.Company

       if ($Usr.Office){      
         $Lipemza = $Usr.Office
	     $Office = $Lipemza.replace("'","")
        }else{$Office = $Usr.Office}

		$City = $Usr.City

       if ($Usr.DistinguishedName){      
         $Lipemza = $Usr.DistinguishedName
	     $DistinguishedName = $Lipemza.replace("'","")
        }else{$DistinguishedName = $Usr.DistinguishedName}

       if ($Usr.MemberOf){      
         $Lipemza = $Usr.MemberOf
	     $MemberOf = $Lipemza.replace("'","")
        }else{$MemberOf = $Usr.MemberOf}


    $createTimeStamp = $Usr.createTimeStamp
	$Deleted = $Usr.Deleted
	$Modified = $Usr.Modified
	$PasswordLastSet = $Usr.PasswordLastSet
	$AccountExpirationDate = $Usr.AccountExpirationDate
	$msExchWhenMailboxCreated = $Usr.msExchWhenMailboxCreated
	$LastLogonDate = $Usr.LastLogonDate
	$EmailAddress = $Usr.EmailAddress
	$MobilePhone = $Usr.MobilePhone
	$msExchRemoteRecipientType = $Usr.msExchRemoteRecipientType
	$ObjectClass = $Usr.ObjectClass
	$PasswordExpired = $Usr.PasswordExpired
	$PasswordNeverExpires = $Usr.PasswordNeverExpires
	$PasswordNotRequired = $Usr.PasswordNotRequired
	$Enabled = $Usr.Enabled
	$LockedOut = $Usr.LockedOut
	$CannotChangePassword = $Usr.CannotChangePassword
    $userAccountControl = $Usr.userAccountControl

#A variável "$SQLQuery" receberar o insert com os dados para ser executado no banco
$SQLQuery = "USE $SQLDatabase
INSERT INTO [brz].[user]
 ([SID],[Name],[DisplayName],[SamAccountName],[mail],[Title],[Department],[Description],[employeeType],[Company]
  ,[Office],[City],[DistinguishedName],[MemberOf],[createTimeStamp],[Deleted],[Modified],[PasswordLastSet],[AccountExpirationDate]
  ,[msExchWhenMailboxCreated],[LastLogonDate],[EmailAddress],[MobilePhone],[msExchRemoteRecipientType]
  ,[ObjectClass],[PasswordExpired],[PasswordNeverExpires],[PasswordNotRequired],[Enabled],[LockedOut]
  ,[CannotChangePassword],[userAccountControl])
VALUES ('$SID','$Name','$DisplayName','$SamAccountName','$mail','$Title','$Department','$Description','$employeeType','$Company',
	'$Office','$City','$DistinguishedName','$MemberOf','$createTimeStamp','$Deleted','$Modified','$PasswordLastSet','$AccountExpirationDate',
	'$msExchWhenMailboxCreated','$LastLogonDate','$EmailAddress','$MobilePhone','$msExchRemoteRecipientType',
	'$ObjectClass','$PasswordExpired','$PasswordNeverExpires','$PasswordNotRequired','$Enabled','$LockedOut',
    '$CannotChangePassword','$userAccountControl');"


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