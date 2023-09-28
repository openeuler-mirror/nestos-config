# NestOS-Config

[NestOS](https://nestos.openeuler.org/)是在openEuler社区孵化的云底座操作系统，分为面向虚拟化的NestOS For Virt（NFV）和面向容器云场景的NestOS For Container（NFC）两个版本。NFV基于yum/dnf软件包管理器，由oemaker集成构建。NFC集成了rpm-ostree支持、ignition配置等技术，采用双根文件系统、原子化更新的设计思路，使用nestos-assembler快速集成构建。

本代码仓库为构建NestOS所需的基础配置文件。



## 关于本代码仓

- **NestOS-For-Container** 为NestOS For Container版本构建配置，供NestOS-assembler使用。
    - **manifest文件夹** 包含很多.yaml配置文件，软件包统一放置于rpm-lists.yaml中。
    - **overlay.d文件夹** 中的文件可以根据其目录结构覆盖软件包提供的初始文件。
    - **manifest.ymal**  包含用于更新的stream名称以及releasever。


- **NestOS-For-Virt** 为NestOS For Virt版本构建配置，供oemaker使用。
    - oemaker的详细使用说明请参阅 [oemaker官方仓库](https://gitee.com/openeuler/oemaker)

其他配置文件中具体参数的使用方法，如在使用过程中仍有疑问，可以提交issue至本仓库，或加入sig-CloudNative或sig-K8sDistro与开发者们一起交流。

## 仓库更新流程

1. Bump releasever in manifest.yaml
2. Update the repos in manifest.yaml if needed
3. Run nosa fetch --update-lockfile
4. PR the result