#!/usr/bin/env python3
"""
iCloud CloudKit設定を自動化するスクリプト
GitHub Actionsで実行され、XcodeプロジェクトにiCloud Capabilityを追加します
"""
import re
import sys

def update_entitlements(entitlements_path, container_id):
    """EntitlementsファイルのコンテナIDを更新"""
    print(f"Updating entitlements file: {entitlements_path}")

    with open(entitlements_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # プレースホルダーを実際のコンテナIDに置換
    content = content.replace('iCloud.com.yourname.BottleKeeper', container_id)

    with open(entitlements_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"✓ Updated container ID to: {container_id}")

def update_core_data_manager(file_path, container_id):
    """CoreDataManager.swiftのコンテナIDを更新"""
    print(f"Updating CoreDataManager: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # プレースホルダーを実際のコンテナIDに置換
    content = content.replace('iCloud.com.yourname.BottleKeeper', container_id)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"✓ Updated CoreDataManager container ID to: {container_id}")

def add_icloud_capability_to_project(project_path, target_id, entitlements_path):
    """project.pbxproj に iCloud Capability を追加"""
    print(f"Adding iCloud capability to project: {project_path}")

    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # PBXProject セクションを見つける
    project_section_match = re.search(
        r'/\* Begin PBXProject section \*/.*?(/\* End PBXProject section \*/)',
        content,
        re.DOTALL
    )

    if not project_section_match:
        print("✗ PBXProject section not found")
        return False

    # TargetAttributes を探す
    target_attributes_pattern = r'TargetAttributes = \{(.*?)\};'
    target_attributes_match = re.search(target_attributes_pattern, content, re.DOTALL)

    if target_attributes_match:
        # 既存の TargetAttributes がある場合
        target_attrs_content = target_attributes_match.group(1)

        # 該当ターゲットに SystemCapabilities を追加
        target_pattern = f'{target_id} = {{(.*?)}};'
        target_match = re.search(target_pattern, target_attrs_content, re.DOTALL)

        if target_match:
            target_content = target_match.group(1)

            # SystemCapabilities がすでにあるか確認
            if 'SystemCapabilities' in target_content:
                print("✓ iCloud capability already configured")
                return True

            # SystemCapabilities を追加
            new_target_content = target_content.rstrip() + '''
\t\t\t\t\tSystemCapabilities = {
\t\t\t\t\t\tcom.apple.iCloud = {
\t\t\t\t\t\t\tenabled = 1;
\t\t\t\t\t\t};
\t\t\t\t\t};
\t\t\t\t\tcom.apple.ApplicationGroups.iOS = {
\t\t\t\t\t\tenabled = 0;
\t\t\t\t\t};
'''
            # 置換
            old_target_block = f'{target_id} = {{{target_content}}};'
            new_target_block = f'{target_id} = {{{new_target_content}\t\t\t\t}};'
            content = content.replace(old_target_block, new_target_block)
    else:
        print("✗ TargetAttributes not found in project")
        return False

    # CODE_SIGN_ENTITLEMENTS を追加（まだない場合）
    # XCBuildConfiguration セクションで BottleKeeper ターゲットの設定を探す
    build_config_pattern = r'(/\* (Debug|Release) \*/ = \{[^}]*name = (Debug|Release);[^}]*buildSettings = \{[^}]*)\};'

    def add_entitlements_if_needed(match):
        config_content = match.group(0)
        # BottleKeeperTests は除外
        if 'BottleKeeperTests' in config_content:
            return config_content
        # すでに CODE_SIGN_ENTITLEMENTS がある場合はスキップ
        if 'CODE_SIGN_ENTITLEMENTS' in config_content:
            return config_content
        # PRODUCT_BUNDLE_IDENTIFIER がある設定にのみ追加
        if 'PRODUCT_BUNDLE_IDENTIFIER' not in config_content:
            return config_content

        # CODE_SIGN_ENTITLEMENTS を追加
        insert_text = f'\t\t\t\tCODE_SIGN_ENTITLEMENTS = {entitlements_path};\n\t\t\t'
        config_content = config_content.replace('};', insert_text + '};')
        return config_content

    content = re.sub(build_config_pattern, add_entitlements_if_needed, content, flags=re.DOTALL)

    # ファイルに書き込み
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("✓ Added iCloud capability to project")
    return True

def find_target_id(project_path, target_name='BottleKeeper'):
    """ターゲットIDを見つける"""
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # PBXNativeTarget セクションからターゲットIDを探す
    target_pattern = f'([A-F0-9]{{24}}) /\\* {target_name} \\*/ = {{\\s*isa = PBXNativeTarget;'
    match = re.search(target_pattern, content)

    if match:
        return match.group(1)

    return None

def main():
    bundle_id = sys.argv[1] if len(sys.argv) > 1 else 'com.bottlekeep.whiskey'

    # iCloud Container ID を構築
    container_id = f'iCloud.{bundle_id}'

    print(f"=== iCloud CloudKit Setup ===")
    print(f"Bundle ID: {bundle_id}")
    print(f"Container ID: {container_id}")
    print()

    # 1. Entitlements を更新
    entitlements_path = 'BottleKeeper/BottleKeeper.entitlements'
    update_entitlements(entitlements_path, container_id)
    print()

    # 2. CoreDataManager を更新
    core_data_path = 'BottleKeeper/Services/CoreDataManager.swift'
    update_core_data_manager(core_data_path, container_id)
    print()

    # 3. Xcode プロジェクトに iCloud Capability を追加
    project_path = 'BottleKeeper.xcodeproj/project.pbxproj'
    target_id = find_target_id(project_path)

    if not target_id:
        print("✗ Could not find BottleKeeper target ID")
        sys.exit(1)

    print(f"Target ID: {target_id}")

    success = add_icloud_capability_to_project(
        project_path,
        target_id,
        entitlements_path
    )

    if success:
        print()
        print("✓ iCloud CloudKit setup completed successfully!")
        print()
        print("Next steps:")
        print("1. Commit and push changes")
        print("2. Run iOS build workflow to deploy to TestFlight")
        print("3. Install app on multiple devices with same iCloud account")
        print("4. Data will sync automatically between devices")
    else:
        print("✗ Setup failed")
        sys.exit(1)

if __name__ == '__main__':
    main()
