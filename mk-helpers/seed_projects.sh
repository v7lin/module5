source data/creds.env
source mk-helpers/env.vars
eval $(docker-machine env $machine)


BACKUP=1488464969_2017_03_02
BACKUP_FILE=$BACKUP_gitlab_backup.tar.gz

printf "Подгтовка проектов\n"
docker-compose exec gitlab wget https://s3.eu-central-1.amazonaws.com/docker-mk-mar-2017/module5/$BACKUP_FILE -P /var/opt/gitlab/backups/

printf "Импортируем проекты\nОтвечаем 'yes' в терминале на вопросы\n"
docker-compose exec gitlab /opt/gitlab/bin/gitlab-rake gitlab:backup:restore BACKUP=$BACKUP


printf "\nАктуализируем конфигурацию CI"
for i in `seq 1 6`;
do
  docker-compose exec -T gitlab gitlab-rails runner "Ci::Variable.create :key => \"DOCKERHUB_USER\", :value => \"$DOCKERHUB_USER\", :gl_project_id => $i; \
    Ci::Variable.create :key => \"DOCKERHUB_PASSWORD\", :value => \"$DOCKERHUB_PASSWORD\", :gl_project_id => $i; \
    Ci::Variable.create :key => \"DEV_HOST\", :value => \"$module5_host\", :gl_project_id => $i; \
    Ci::Variable.create :key => \"GUSER\", :value => \"$GITLAB_USER\", :gl_project_id => $i; \
    Ci::Variable.create :key => \"GPASSWORD\", :value => \"$GITLAB_PASSWORD\", :gl_project_id => $i"
    printf "."
done

printf "\nРегистрируем CI агент\n"
docker-compose exec gitlab_runner gitlab-runner register -n
