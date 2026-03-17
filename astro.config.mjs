// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mermaid from 'astro-mermaid';
import starlightImageZoom from 'starlight-image-zoom';
import starlightLinksValidator from 'starlight-links-validator';
import starlightUtils from '@lorenzo_lewis/starlight-utils';

// https://astro.build/config
export default defineConfig({
	integrations: [
		mermaid(),
		starlight({
			title: 'PowerShell 学習ガイド',
			defaultLocale: 'root',
			locales: {
				root: {
					label: '日本語',
					lang: 'ja',
				},
			},
			plugins: [
				starlightImageZoom(),
				starlightLinksValidator({
					errorOnRelativeLinks: false,
				}),
				starlightUtils({
					multiSidebar: {
						switcherStyle: 'horizontalList',
					},
				}),
			],
			sidebar: [
				{
					label: '第1部: 基礎',
					collapsed: false,
					items: [
						{
							label: '第1章: PowerShellの世界',
							collapsed: true,
							autogenerate: { directory: '01-overview' },
						},
						{
							label: '第2章: 環境構築と最初の一歩',
							collapsed: true,
							autogenerate: { directory: '02-setup' },
						},
						{
							label: '第3章: コマンドレットとヘルプシステム',
							collapsed: true,
							autogenerate: { directory: '03-cmdlets' },
						},
						{
							label: '第4章: パイプラインとオブジェクト',
							collapsed: true,
							autogenerate: { directory: '04-pipeline' },
						},
						{
							label: '第5章: 変数・データ型・演算子',
							collapsed: true,
							autogenerate: { directory: '05-variables' },
						},
						{
							label: '第6章: 制御構文',
							collapsed: true,
							autogenerate: { directory: '06-control-flow' },
						},
					],
				},
				{
					label: '第2部: 中級',
					collapsed: false,
					items: [
						{
							label: '第7章: 関数とスクリプト',
							collapsed: true,
							autogenerate: { directory: '07-functions' },
						},
						{
							label: '第8章: エラー処理とデバッグ',
							collapsed: true,
							autogenerate: { directory: '08-error-handling' },
						},
						{
							label: '第9章: モジュールとパッケージ管理',
							collapsed: true,
							autogenerate: { directory: '09-modules' },
						},
						{
							label: '第10章: ファイル操作とデータ処理',
							collapsed: true,
							autogenerate: { directory: '10-file-data' },
						},
						{
							label: '第11章: プロバイダーとドライブ',
							collapsed: true,
							autogenerate: { directory: '11-providers' },
						},
					],
				},
				{
					label: '第3部: 上級',
					collapsed: false,
					items: [
						{
							label: '第12章: 高度な関数とツール作成',
							collapsed: true,
							autogenerate: { directory: '12-advanced-tools' },
						},
						{
							label: '第13章: 正規表現',
							collapsed: true,
							autogenerate: { directory: '13-regex' },
						},
						{
							label: '第14章: クラスとオブジェクト指向',
							collapsed: true,
							autogenerate: { directory: '14-classes' },
						},
						{
							label: '第15章: リモート管理とジョブ',
							collapsed: true,
							autogenerate: { directory: '15-remoting' },
						},
						{
							label: '第16章: テストとコード品質',
							collapsed: true,
							autogenerate: { directory: '16-testing' },
						},
						{
							label: '第17章: ベストプラクティス',
							collapsed: true,
							autogenerate: { directory: '17-best-practices' },
						},
					],
				},
				{
					label: '第4部: 実践プロジェクト',
					collapsed: false,
					items: [
						{
							label: '第18章: DevOps Monitor Toolkit',
							collapsed: true,
							autogenerate: { directory: '18-sample-project' },
						},
					],
				},
			],
		}),
	],
});
