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
																@"lst_rival_lv":@0,
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

//ライバルをトップランカー/クソザコにする
%hook RBMusicCPUView

	-(int)level {

		if (isEnabled && [preferences[@"lst_rival_lv"]intValue] != 0) {
			return [preferences[@"lst_rival_lv"]intValue];
		}
		else {
			return %orig;
		}

	}

	-(id)selectedImage {

		//スライダーのつまみを消す
		if (isEnabled && [preferences[@"lst_rival_lv"]intValue] != 0) {
			return nil;
		}
		else {
			return %orig;
		}

	}

	-(id)sliderView {

		//有効時にスライダーを消し、ロックされている旨を示すメッセージを表示する
		if (isEnabled && [preferences[@"lst_rival_lv"]intValue] != 0) {

			NSString *text = @"Locked by RB plus Enhancer";
			// 描画するサイズ
	    CGSize size = CGSizeMake(272, 50);

	    // ビットマップ形式のグラフィックスコンテキストの生成
	    // 第2引数のopaqueを`NO`にすることで背景が透明になる
	    UIGraphicsBeginImageContextWithOptions(size, NO, 0);


	    // 描画する文字列の情報を指定する
	    //--------------------------------------

	    // 文字描画時に反映される影の指定
	    NSShadow *shadow = [[NSShadow alloc] init];
	    shadow.shadowOffset = CGSizeMake(0.f, -0.5f);
	    shadow.shadowColor = [UIColor darkGrayColor];
	    shadow.shadowBlurRadius = 0.f;

	    // 文字描画に使用するフォントの指定
	    UIFont *font = [UIFont boldSystemFontOfSize:20.0f];

	    // パラグラフ関連の情報の指定
	    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	    style.alignment = NSTextAlignmentCenter;
	    style.lineBreakMode = NSLineBreakByClipping;

	    NSDictionary *attributes = @{
	           NSFontAttributeName: font,
	           NSParagraphStyleAttributeName: style,
	           NSShadowAttributeName: shadow,
	           NSForegroundColorAttributeName: [UIColor blackColor],
	           NSBackgroundColorAttributeName: [UIColor clearColor]
	    };

	    // 文字列を描画する
	    [text drawInRect:CGRectMake(1, 14, size.width, size.height)
	      withAttributes:attributes];

	    // 現在のグラフィックスコンテキストの画像を取得する
	    UIImage *image = nil;
	    image = UIGraphicsGetImageFromCurrentImageContext();

	    // 現在のグラフィックスコンテキストへの編集を終了
	    // (スタックの先頭から削除する)
	    UIGraphicsEndImageContext();

			UIImageView *iv = [[UIImageView alloc] initWithImage:image];
			return iv;
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
