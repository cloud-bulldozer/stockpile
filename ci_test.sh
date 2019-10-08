#/bin/bash

set -x

# Prep the results.markdown file
echo "Results for "$JOB_NAME > results.markdown
echo "" >> results.markdown
echo 'Tag | ok | changed | unreachable | failed | skipped | rescued | ignored' >> results.markdown
echo '-----|---|---------|-------------|--------|---------|---------|------' >> results.markdown

kube_config=$1

# Setup hosts and vars for CI environment
cp ci/all.yml group_vars/all.yml

# Get the list of tags from stockpile.yml (minus lines beginning with #)
tag_list=`grep tags stockpile.yml | grep -v '^ *#'| awk '{print $6}'`

for tag in $tag_list
do
  echo "Running tag: "$tag
  results=`ansible-playbook -i ci/hosts stockpile.yml -e kube_config=$kube_config --tags=$tag | grep "ok=.*changed=.*unreachable=.*failed=.*skipped=.*rescued=.*ignored=.*"`

  echo $results
  
  # set resulting variables
  res=`echo $results | sed 's/=/ /g'`
  ok=`echo $res | awk '{print $4}'`
  changed=`echo $res | awk '{print $6}'`
  unreachable=`echo $res | awk '{print $8}'`
  failed=`echo $res | awk '{print $10}'`
  skipped=`echo $res | awk '{print $12}'`
  rescued=`echo $res | awk '{print $14}'`
  ignored=`echo $res | awk '{print $16}'`

  echo $tag"|"$ok"|"$changed"|"$unreachable"|"$failed"|"$skipped"|"$rescued"|"$ignored >> results.markdown
done
