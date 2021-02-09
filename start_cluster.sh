full_path=$(realpath $0)
dir_path=$(dirname $full_path)

kind create cluster --name lanjie --config ${dir_path}/kindClusterConfig/config.yaml
