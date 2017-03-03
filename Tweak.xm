static NSString *const kSettingsPath = @"/var/mobile/Library/Preferences/jp.i4m1k0su.rbplusenhancer.plist";
static const float kNoSeeThrough = 1.0f;

NSMutableDictionary *preferences;
BOOL isEnabled = NO;
int doublePlayFlag = 0;
float originalRivalAlpha = 0.0;

//設定ファイルロード
static void loadPreferences() {

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
			[defaultPreferences release];

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

//起動時の処理
%ctor {
	loadPreferences();
}


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

			NSString *text = @"\nLocked by RB plus Enhancer";
			// 描画するサイズ
			//オリジナルの値を取得
			UIImageView *originalUIImageView = %orig;
			CGSize size = CGSizeMake([originalUIImageView frame].size.width, [originalUIImageView frame].size.height + 10);
			//[originalUIImageView release];
			float fontSize = 29.0f;
			NSNumber *stroke = @-2.0;
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				//stroke = @-2.0;
				fontSize = 22.0f;
			}

	    // ビットマップ形式のグラフィックスコンテキストの生成
	    // 第2引数のopaqueを`NO`にすることで背景が透明になる
	    UIGraphicsBeginImageContextWithOptions(size, NO, 0);


	    // 描画する文字列の情報を指定する
	    //--------------------------------------

	    // 文字描画に使用するフォントの指定
	    UIFont *font = [UIFont boldSystemFontOfSize:fontSize];

	    // パラグラフ関連の情報の指定
	    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	    style.alignment = NSTextAlignmentCenter;
	    style.lineBreakMode = NSLineBreakByClipping;

	    NSDictionary *attributes = @{
	           NSFontAttributeName: font,
	           NSParagraphStyleAttributeName: style,
	           //NSShadowAttributeName: shadow,
						 NSStrokeWidthAttributeName:stroke,//@-1.0,
						 NSStrokeColorAttributeName:[UIColor whiteColor],
	           NSForegroundColorAttributeName: [UIColor blackColor],
	           NSBackgroundColorAttributeName: [UIColor clearColor]
	    };

	    // 文字列を描画する
	    [text drawInRect:CGRectMake(0, 0, size.width, size.height) withAttributes:attributes];

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

//ライムポイント固定
%hook RBExperienceData

	-(float)getPoint {
		return 99999.9;
	}

%end
