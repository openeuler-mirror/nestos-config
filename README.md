# NestOS-Config

[NestOS](https://nestos.openeuler.org/)是在openEuler社区孵化的云底座操作系统，集成了rpm-ostree支持、ignition配置等技术，采用双根文件系统、原子化更新的设计思路，使用nestos-assembler快速集成构建。

本代码仓库为构建NestOS所需的基础配置文件。



## 关于本代码仓

- **manifest文件夹** 包含很多.yaml配置文件，软件包按照功能/使用场景的不同，分类放在这些配置文件中。
- **overlay.d文件夹** 中的文件可以根据其目录结构覆盖软件包提供的初始文件。
- **manifest.ymal**  包含用于更新的stream名称以及releasever。

其他配置文件中具体参数的使用方法，如在使用过程中仍有疑问，可以提交issue至本仓库，或加入sig-CloudNative或sig-K8sDistro与开发者们一起交流。

## 仓库更新流程

1. Bump releasever in manifest.yaml
2. Update the repos in manifest.yaml if needed
3. Run nosa fetch --update-lockfile
4. PR the result