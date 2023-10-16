
PathToConfigFolder=./initial-config

# ustawienie wartosci data dla zmiennych pod db2

data_github_barauth=eyJhdXRoVHlwZSI6IkJBU0lDX0FVVEgiLCJjcmVkZW50aWFscyI6eyJ1c2VybmFtZSI6Im1ncm9jaG8iLCJwYXNzd29yZCI6ImdocF9KVTFVSHdMcTFLRWVYdDlQWWNScUI0NlE0enRySWoxSWREYXEifX0K
data_db2_odbc=$(base64 -i ${PathToConfigFolder}/odbcini/odbc.ini)

zip -r -X ${PathToConfigFolder}/extensions/extensions.zip ${PathToConfigFolder}/extensions/db2cli.ini
data_db2_db2cli=$(base64 -i ${PathToConfigFolder}/extensions/extensions.zip)

data_credentials=$(base64 -i ${PathToConfigFolder}/setdbparms/setdbparms.txt)

# TEST
# echo $data_db2_db2cli

# prefix for name
prefix='michal'

# tworzenie github-barauth

cat <<EOF | oc apply -f - 
apiVersion: appconnect.ibm.com/v1beta1
kind: Configuration
metadata:
  name: ${prefix}-github-barauth
  namespace: cp4i
spec:
  data: ${data_github_barauth}
  description: Authentication for GitHub
  type: barauth
EOF


# tworzenie odbc.ini

cat <<EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Configuration
metadata:
  name: ${prefix}-db2-odbcini
  namespace: cp4i
spec:
  type: odbc
  description: Configuration for Db2
  data: ${data_db2_odbc}
EOF

# tworzenie db2cli.ini

cat <<EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Configuration
metadata:
  name: ${prefix}-extensions
  namespace: cp4i
spec:
  type: generic
  description: Files for configuring Db2
  data: ${data_db2_db2cli}
EOF

# tworzenie setdbparms.txt

cat <<EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Configuration
metadata:
  name: ${prefix}-db2-credentials
  namespace: cp4i
spec:
  type: setdbparms  
  description: Configuration for Db2 
  data: ${data_credentials}
EOF

# tworzenie integration-server.yaml

oc delete integrationserver ${prefix}-test-database-app

:'
cat <<EOF | oc apply -f -
sdfsapiVersion: appconnect.ibm.com/v1beta1
kind: IntegrationServer
metadata:
  name: ${prefix}-test-database-app
  labels: {}
spec:
  adminServerSecure: false
  barURL: >-
    https://github.com/mgrocho/ACE_Tekton_Operators/raw/main/ace-toolkit-code/ExampleDatabaseCompute/BAR/ExampleAppBAR.bar
  configurations:
    - ${prefix}-github-barauth
    - ${prefix}-db2-odbcini
    - ${prefix}-extensions
    - ${prefix}-db2-credentials
  createDashboardUsers: true
  designerFlowsOperationMode: disabled
  enableMetrics: true
  env:
    - name: DB2CLIINIPATH
      value: '/home/aceuser/generic/'
  license:
    accept: true
    license: L-APEH-CJUCNR
    use: AppConnectEnterpriseProduction
  pod:
    containers:
      runtime:
        resources:
          limits:
            cpu: 300m
            memory: 350Mi
          requests:
            cpu: 300m
            memory: 300Mi
  replicas: 1
  router:
    timeout: 120s
  service:
    endpointType: http
  version: '12.0'
EOF
'

cat <<EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: IntegrationServer
metadata:
  name: ${prefix}-test-database-app
  labels: {}
spec:
  adminServerSecure: false
  barURL: >-
    https://github.com/mgrocho/ACE_Tekton_Operators/raw/main/ace-toolkit-code/ExampleDatabaseCompute/BAR/ExampleAppBAR.bar
  configurations:
    - ${prefix}-github-barauth
    - mybarname-odbcini
    - mybarname-generic
    - mybarname-setdbparms
    - mybarname-policy
    - mybarname-serverconf
  createDashboardUsers: true
  designerFlowsOperationMode: disabled
  enableMetrics: true
  env:
    - name: DB2CLIINIPATH
      value: '/home/aceuser/generic'
  license:
    accept: true
    license: L-APEH-CJUCNR
    use: AppConnectEnterpriseProduction
  pod:
    containers:
      runtime:
        resources:
          limits:
            cpu: 300m
            memory: 350Mi
          requests:
            cpu: 300m
            memory: 300Mi
  replicas: 1
  router:
    timeout: 120s
  service:
    endpointType: http
  version: '12.0'
EOF
