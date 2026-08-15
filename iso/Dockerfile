FROM archlinux:latest

# 准备可用镜像源并安装构建工具（mkarchiso 需要 root，镜像内默认即 root）
RUN echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist \
 && pacman -Syu --noconfirm \
 && pacman -S --noconfirm archiso grub syslinux dosfstools

WORKDIR /xos
COPY iso/profiles/xos ./profiles/xos
COPY shell/xos-shell ./shell/xos-shell
COPY shell/xos-settings ./shell/xos-settings

# 同步 shell 源码进 profile（customize_airootfs.sh 会编译它们）
RUN mkdir -p profiles/xos/airootfs/opt \
 && rm -rf profiles/xos/airootfs/opt/xos-shell-src \
 && cp -r shell/xos-shell profiles/xos/airootfs/opt/xos-shell-src \
 && rm -rf profiles/xos/airootfs/opt/xos-settings-src \
 && cp -r shell/xos-settings profiles/xos/airootfs/opt/xos-settings-src

# 不在构建期编译 ISO；由 docker-build.sh 在挂载 out/ 的容器内执行
CMD ["sh", "-c", "mkarchiso -v -w /xos/work -o /xos/out profiles/xos"]
