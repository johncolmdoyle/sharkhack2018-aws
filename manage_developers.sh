#!/usr/bin/bash

create_user() {
	echo "user: ${1}"

	GENERATED_PASSWORD=`curl --silent "https://www.random.org/strings/?num=1&len=12&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new"`

	CREATE_USER_RESPONSE=`aws iam create-user --user-name ${1} --profile sharkhack`;
	ACCESS_KEY_RESPONSE=`aws iam create-access-key --user-name ${1} --output json --profile sharkhack`;
	LOGIN_PASSWORD_RESPONSE=`aws iam create-login-profile --user-name ${1} --password ${GENERATED_PASSWORD} --no-password-reset-required --profile sharkhack`;
	ADD_GROUP_RESPONSE=`aws iam add-user-to-group --group-name Developers --user-name ${1} --profile sharkhack`;

	ACCESS_KEY_ID=`echo ${ACCESS_KEY_RESPONSE} | python -c "import sys, json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])"`;
	SECRET_ACCESS_KEY=`echo ${ACCESS_KEY_RESPONSE} | python -c "import sys, json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])"`;

	echo "${1},${GENERATED_PASSWORD},${ACCESS_KEY_ID},${SECRET_ACCESS_KEY}" >> user_data.csv;
}

delete_user() {
	echo "user: ${1}"
	ACCESS_KEY_ID=`cat user_data.csv | grep ${1} | cut -d, -f3 | head -n 1`; 

	REMOVE_GROUP_RESPONSE=`aws iam remove-user-from-group --group-name Developers --user-name ${1} --profile sharkhack`;
	DELETE_ACCESS_KEY_RESPONSE=`aws iam delete-access-key --user-name ${1} --access-key-id ${ACCESS_KEY_ID} --profile sharkhack`;
	REMOVE_LOGIN_PASSWORD_RESPONSE=`aws iam delete-login-profile --user-name ${1} --profile sharkhack`;
	DELETE_USER_RESPONSE=`aws iam delete-user --user-name ${1} --profile sharkhack`;
}

if [ "${1}" == "create" ]; then
	for (( i=1; i <= ${2}; i++ ))
	do
		create_user "sh2018-${i}"
	done
elif [ "${1}" == "delete" ]; then
	for (( i=1; i<=$(wc -l < user_data.csv); i++ ))
	do
		delete_user "sh2018-${i}"
	done

	rm user_data.csv;
fi