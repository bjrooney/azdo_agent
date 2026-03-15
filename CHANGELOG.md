# Changelog

## [0.6.1](https://github.com/bjrooney/azdo_agent/compare/v0.6.0...v0.6.1) (2026-03-15)


### Bug Fixes

* use colon separator for apko --annotations flag ([b3e77d8](https://github.com/bjrooney/azdo_agent/commit/b3e77d805690c3fe6227cb1d12cc7d611210e06d))

## [0.6.0](https://github.com/bjrooney/azdo_agent/compare/v0.5.0...v0.6.0) (2026-03-15)


### Features

* add OCI image annotations and push vMAJOR semver tag ([0044940](https://github.com/bjrooney/azdo_agent/commit/0044940eb631d189d7bf3670f68bb229d2f4f347))
* add OCI image annotations and push vMAJOR semver tag ([dcba9a1](https://github.com/bjrooney/azdo_agent/commit/dcba9a19024005e644b14ab567674ba06d3daf3e))

## [0.5.0](https://github.com/bjrooney/azdo_agent/compare/v0.4.1...v0.5.0) (2026-03-15)


### Features

* pre-bake Azure Pipelines agent into image to eliminate startup download ([514106a](https://github.com/bjrooney/azdo_agent/commit/514106a01d7f013709aae370b4899ec71f46fe30))


### Bug Fixes

* add musl runtime dep for pre-baked Azure Pipelines agent binaries ([5c2c297](https://github.com/bjrooney/azdo_agent/commit/5c2c297069ff6cef5f57bbaf757bdbdd763a6d56))
* move musl dep to apko.yaml for agent binary shared library resolution ([c8121e0](https://github.com/bjrooney/azdo_agent/commit/c8121e0746c33426f5cd3ade61409c0d72daf6d1))
* suppress melange auto-dep scanning for agent binaries ([af36f66](https://github.com/bjrooney/azdo_agent/commit/af36f66cabba3d1c680901448f5465659ece872e))

## [0.4.1](https://github.com/bjrooney/azdo_agent/compare/v0.4.0...v0.4.1) (2026-03-15)


### Bug Fixes

* restore entrypoint /azp/start.sh in apko.yaml ([a47a54b](https://github.com/bjrooney/azdo_agent/commit/a47a54baded5bd444d10ff7c07d20225fff3b76e))

## [0.4.0](https://github.com/bjrooney/azdo_agent/compare/v0.3.0...v0.4.0) (2026-03-15)


### Features

* publish OCI image to GitHub Container Registry on release ([b2c87c8](https://github.com/bjrooney/azdo_agent/commit/b2c87c83f3c3babc0229095e1a005da224cb1286))
* publish OCI image to GitHub Container Registry on release ([7051ab4](https://github.com/bjrooney/azdo_agent/commit/7051ab40812f6d6d259412237f7273c859d7b7c0))

## [0.3.0](https://github.com/bjrooney/azdo_agent/compare/v0.2.0...v0.3.0) (2026-03-15)


### Features

* publish APK packages and index as release assets ([18dc079](https://github.com/bjrooney/azdo_agent/commit/18dc07923f3da45f9c1bbb3323989bc84303a551))


### Bug Fixes

* release-please version.txt and publish APK packages ([5c18728](https://github.com/bjrooney/azdo_agent/commit/5c1872883c240aa629943dfb2dea8de54e13556c))

## [0.2.0](https://github.com/bjrooney/azdo_agent/compare/v0.1.0...v0.2.0) (2026-03-15)


### Features

* add release-please versioning and publish workflow ([814d906](https://github.com/bjrooney/azdo_agent/commit/814d9066bdccc8bbbecc0dd1095228bbc4221d4e))
* add Renovate version management for all toolchain dependencies ([97fae06](https://github.com/bjrooney/azdo_agent/commit/97fae067e779a64cdc33e7e4b26794391360953b))
* **agent:** added terraform helm kluctl kubectl kubelogin helm powershell yq ([6022d72](https://github.com/bjrooney/azdo_agent/commit/6022d727125625a77ab5573f17d0547937c8d58e))
* **agent:** modified to use alpine ([cf53444](https://github.com/bjrooney/azdo_agent/commit/cf53444f5b8bd2c83aeeac03e4a7386712ecd9f5))
* **agent:** tidy ([d7d6513](https://github.com/bjrooney/azdo_agent/commit/d7d65132cd839a847aaafe94e66ce6a32a810b6c))
* **agent:** update ref for portfolio common and add stage ([3eba9b0](https://github.com/bjrooney/azdo_agent/commit/3eba9b091706f7378163b12e4914b49daaea52e5))
* apply ENV ([891d19b](https://github.com/bjrooney/azdo_agent/commit/891d19bc360f589da527adce2eddf4f15ca75c98))
* apply ENV ([58ea78a](https://github.com/bjrooney/azdo_agent/commit/58ea78a75452505be82f9fdd27354f523c369e19))
* automated versioning and release publishing ([253e936](https://github.com/bjrooney/azdo_agent/commit/253e9366e674fc12b2c512a3ca4f187ed3551fa7))
* azdo_agent ([3d35914](https://github.com/bjrooney/azdo_agent/commit/3d35914f402402a2b7a6e89f62719d8e9d615c3a))
* fix krew ([a8c9461](https://github.com/bjrooney/azdo_agent/commit/a8c94613daf55768311b174660f1b5e67d5c6870))
* migrate azdo-agent to Wolfi-native apko/melange pipeline ([77e2610](https://github.com/bjrooney/azdo_agent/commit/77e2610c95f384850d497daa92eb605ca8c3bca5))
* multi-arch build (amd64 + arm64) ([45fc3ec](https://github.com/bjrooney/azdo_agent/commit/45fc3ec1351fb30d26a976edb4b06692ae912e99))
* multi-arch build for amd64 and arm64 (Apple Silicon M2) ([c87c858](https://github.com/bjrooney/azdo_agent/commit/c87c858536aaaa30f8416e24cb0846f49bd8fac9))
* refactor ([a279b3b](https://github.com/bjrooney/azdo_agent/commit/a279b3b8c001e105c5b030577cc5e8f13a2f9d19))
* refactor Dockerfile ([09a2981](https://github.com/bjrooney/azdo_agent/commit/09a29810bd983309f65902050ca432f325022b4d))
* Renovate version management + amd64-only CI ([3140c5d](https://github.com/bjrooney/azdo_agent/commit/3140c5dc618211a4153081b1452d4bd303ea4d40))
* replace pip azure-cli with Wolfi 'az' APK ([d0404b0](https://github.com/bjrooney/azdo_agent/commit/d0404b0c001e514d67234f82ebf4546c3f6dc070))
* tidy ([6981207](https://github.com/bjrooney/azdo_agent/commit/6981207b841547cc89c5038455679c4277729fa5))
* tidy ([ededc99](https://github.com/bjrooney/azdo_agent/commit/ededc995278c4a50dc43f91ea7033865913594d5))
* tidy ([f258a27](https://github.com/bjrooney/azdo_agent/commit/f258a27cabe2287664baf7856ca37788bb610ad2))
* tidy ([2237976](https://github.com/bjrooney/azdo_agent/commit/2237976543274c4a5c3c3ee4ffc1a01fdfb27c1e))
* tidy Dockerfile ([4cbd36f](https://github.com/bjrooney/azdo_agent/commit/4cbd36fa8fdda0dfdb21c8886fafee143952f13e))
* tidy Dockerfile ([831327e](https://github.com/bjrooney/azdo_agent/commit/831327e301ba2659300aa7f0686325cd12546699))
* update VENDIR ([5c862d2](https://github.com/bjrooney/azdo_agent/commit/5c862d24482a2925ffd3be4dd260ea938e4ba278))
* update VENDIR ([17d4fcf](https://github.com/bjrooney/azdo_agent/commit/17d4fcfbb2323d64584a245e51790943097d6405))
* update VENDIR ([2abddd5](https://github.com/bjrooney/azdo_agent/commit/2abddd54fbfe04067fcb85ed18a8d016db3a2e54))


### Bug Fixes

* address maintainability and security review findings ([afc2721](https://github.com/bjrooney/azdo_agent/commit/afc27216cd848deacf5eeb234be5401e818060b2))
* correct tar extraction path for apko binary ([603fcad](https://github.com/bjrooney/azdo_agent/commit/603fcadb474aa723033f38c7223add8201be7ef8))
* drop APK epoch suffix from az pin so Renovate can track it ([f9581c6](https://github.com/bjrooney/azdo_agent/commit/f9581c6c1c4f0ab9eb5793449c686261648edb8a))
* explicit entrypoint for apko container (no sh in distroless image) ([2aacf4c](https://github.com/bjrooney/azdo_agent/commit/2aacf4cbd554d27f9c73ec6c021d429254b9b50d))
* install apko from GitHub release (no setup-apko action exists) ([95f0bc2](https://github.com/bjrooney/azdo_agent/commit/95f0bc239c59395469bd48e61fd699c41c601785))
* pin Chainguard melange and apko images to digests in build-apko.sh ([d57f21f](https://github.com/bjrooney/azdo_agent/commit/d57f21fefcba4769d6b6017943300dd5c195a1b5))
* supply chain hardening, security fixes and Renovate coverage ([1c2d271](https://github.com/bjrooney/azdo_agent/commit/1c2d2711fe841e80c62f80c98399a97f5971a609))
* use ~= fuzzy match for az APK to resolve Docker build failure ([de1a476](https://github.com/bjrooney/azdo_agent/commit/de1a47667d929832fd9ef9a497c902ad9e8e01e8))
* use ~= fuzzy match for az APK version to resolve Docker build failure ([0c689c7](https://github.com/bjrooney/azdo_agent/commit/0c689c793ee53a01d2af487eb16b6d08cd161d71))
* use absolute path for apko entrypoint ([5cb20ce](https://github.com/bjrooney/azdo_agent/commit/5cb20cec0a0df2b0c59ec435576e2fd22485ed56))
* use setup-melange/setup-apko actions instead of distroless containers ([f51c2c4](https://github.com/bjrooney/azdo_agent/commit/f51c2c4d60877ab7f13d7f62b02ef034d5cdf6fd))
* use shell for glob expansion in melange index step ([6fbbabc](https://github.com/bjrooney/azdo_agent/commit/6fbbabcaa4fab9358c64e1ad6945f3b52e8ef760))
