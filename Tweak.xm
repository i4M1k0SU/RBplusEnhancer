static NSString *const kSettingsPath = @"/var/mobile/Library/Preferences/pw.bemani.rbplusenhancer.plist";
static const float kNoSeeThrough = 1.0f;

NSMutableDictionary *preferences;
BOOL isEnabled = NO;
int doublePlayFlag = 0;
float originalRivalAlpha = 0.0;

//起動時の処理
%hook AppDelegate

	//起動時に設定ファイルをロード
	-(void)applicationDidBecomeActive:(id)arg1 {
		%orig;

		//設定ファイルの有無チェック
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath: kSettingsPath]) {

				//ない場合にデフォルト設定を作成
				NSDictionary *defaultPreferences = @{@"sw_enabled":@YES,
																@"sl_scale":@10.0f,
																@"sl_speed_x":@10.0f,
																@"sw_super_rival":@NO,
																@"sw_double_play_alpha":@YES,
																@"sw_manual_alpha":@NO,
																@"sl_manual_alpha":@0.25f};

				preferences = [[NSMutableDictionary alloc] initWithDictionary: defaultPreferences];

				#ifdef DEBUG
					BOOL result = [preferences writeToFile: kSettingsPath atomically: YES];
					if (!result) {
						 NSLog(@"ファイルの書き込みに失敗");
					}
				#else
					[preferences writeToFile: kSettingsPath atomically: YES];
				#endif

		} else {
				//あれば読み込み
				preferences = [[NSMutableDictionary alloc] initWithContentsOfFile: kSettingsPath];
		}
		isEnabled = [[preferences objectForKey:@"sw_enabled"]boolValue];
	}

%end

//パステルくんさんを弄る
%hook RBMenuPastelkun

	//サイズ
	-(float)pastelScale {

		if (isEnabled) {
			return [preferences[@"sl_scale"]floatValue];
		}
		else {
			return %orig;
		}

	}

	//歩行速度
	-(float)speedX {

		if (isEnabled) {
			return [preferences[@"sl_speed_x"]floatValue];
		}
		else {
			return %orig;
		}

	}

%end

//ライバルをトップランカーにする
%hook RBMusicCPUView

	-(int)level {

		if (isEnabled && [preferences[@"sw_super_rival"]boolValue]) {
			return 10;
		}
		else {
			return %orig;
		}

	}

%end

//ダブルプレイ時に半透明解除する処理
%hook RBMusicView

	-(void)SelectDoublePlayButton {
		doublePlayFlag = 1;
		%orig;
		//終了時にはダブルプレイAfterフラグ
		doublePlayFlag = 2;
	}

	-(void)SelectDecideButton {
		doublePlayFlag = 0;
		%orig;
	}

%end

%hook RBMusicColorView

	-(float)rivalAlpha {

		float originalReturnValue = %orig;


		if (isEnabled && [preferences[@"sw_double_play_alpha"]boolValue]) {

			//NSLog(@"rivalAlpha");
			switch (doublePlayFlag) {

				//シングルプレー
				case 0:
					if ([preferences[@"sw_manual_alpha"]boolValue]) {
						originalRivalAlpha = [preferences[@"sl_manual_alpha"]floatValue];
					}
					else {
						originalRivalAlpha = originalReturnValue;
					}
					#ifdef DEBUG
						NSLog(@"Single:alpha:%f",originalRivalAlpha);
					#endif
					return originalRivalAlpha;

				//ダブルプレー
				case 1:
					originalRivalAlpha = originalReturnValue;
					#ifdef DEBUG
						NSLog(@"Double:alpha:%f",kNoSeeThrough);
					#endif
					return kNoSeeThrough;

				//ダブルプレー後
				//保持してた値を強制的に返し上書きを防止
				case 2:
					if ([preferences[@"sw_manual_alpha"]boolValue]) {
						return [preferences[@"sl_manual_alpha"]floatValue];
					}
					else {
						#ifdef DEBUG
							NSLog(@"AfterDouble:alpha:%f",originalRivalAlpha);
						#endif
						return originalRivalAlpha;
					}

				default:
					return originalReturnValue;
			}
		}
		else {
			return originalReturnValue;
		}

	}

%end
