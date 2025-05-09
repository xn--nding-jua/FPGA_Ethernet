object mainform: Tmainform
  Left = 600
  Top = 348
  BorderStyle = bsSingle
  Caption = 'UdpAudioTest'
  ClientHeight = 490
  ClientWidth = 842
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Label5: TLabel
    Left = 16
    Top = 8
    Width = 509
    Height = 32
    Caption = 'UDP Audio-Receiver for Multichannel-Audio'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object channelselector_left: TRadioGroup
    Left = 8
    Top = 208
    Width = 569
    Height = 129
    Caption = ' Channel Selector Left '
    Columns = 6
    ItemIndex = 0
    Items.Strings = (
      'Ch 1'
      'Ch 2'
      'Ch 3'
      'Ch 4'
      'Ch 5'
      'Ch 6'
      'Ch 7'
      'Ch 8'
      'Ch 9'
      'Ch 10'
      'Ch 11'
      'Ch 12'
      'Ch 13'
      'Ch 14'
      'Ch 15'
      'Ch 16'
      'Ch 17'
      'Ch 18'
      'Ch 19'
      'Ch 20'
      'Ch 21'
      'Ch 22'
      'Ch 23'
      'Ch 24'
      'Ch 25'
      'Ch 26'
      'Ch 27'
      'Ch 28'
      'Ch 29'
      'Ch 30'
      'Ch 31'
      'Ch 32'
      'Ch 33'
      'Ch 34'
      'Ch 35'
      'Ch 36'
      'Ch 37'
      'Ch 38'
      'Ch 39'
      'Ch 40'
      'Ch 41'
      'Ch 42'
      'Ch 43'
      'Ch 44'
      'Ch 45'
      'Ch 46'
      'Ch 47'
      'Ch 48')
    TabOrder = 0
  end
  object channelselector_right: TRadioGroup
    Left = 8
    Top = 344
    Width = 569
    Height = 129
    Caption = ' Channel Selector Right '
    Columns = 6
    ItemIndex = 1
    Items.Strings = (
      'Ch 1'
      'Ch 2'
      'Ch 3'
      'Ch 4'
      'Ch 5'
      'Ch 6'
      'Ch 7'
      'Ch 8'
      'Ch 9'
      'Ch 10'
      'Ch 11'
      'Ch 12'
      'Ch 13'
      'Ch 14'
      'Ch 15'
      'Ch 16'
      'Ch 17'
      'Ch 18'
      'Ch 19'
      'Ch 20'
      'Ch 21'
      'Ch 22'
      'Ch 23'
      'Ch 24'
      'Ch 25'
      'Ch 26'
      'Ch 27'
      'Ch 28'
      'Ch 29'
      'Ch 30'
      'Ch 31'
      'Ch 32'
      'Ch 33'
      'Ch 34'
      'Ch 35'
      'Ch 36'
      'Ch 37'
      'Ch 38'
      'Ch 39'
      'Ch 40'
      'Ch 41'
      'Ch 42'
      'Ch 43'
      'Ch 44'
      'Ch 45'
      'Ch 46'
      'Ch 47'
      'Ch 48')
    TabOrder = 1
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 48
    Width = 185
    Height = 153
    Caption = ' General Control '
    TabOrder = 2
    object Button1: TButton
      Left = 8
      Top = 24
      Width = 169
      Height = 25
      Caption = 'Enable receiver'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 8
      Top = 120
      Width = 169
      Height = 25
      Caption = 'Send HELLO to FPGA'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button4: TButton
      Left = 8
      Top = 56
      Width = 169
      Height = 25
      Caption = 'Disable receiver'
      TabOrder = 2
      OnClick = Button4Click
    end
    object Button3: TButton
      Left = 8
      Top = 88
      Width = 81
      Height = 25
      Caption = 'Start Audio'
      TabOrder = 3
      OnClick = Button3Click
    end
    object Button5: TButton
      Left = 96
      Top = 88
      Width = 81
      Height = 25
      Caption = 'Stop Audio'
      TabOrder = 4
      OnClick = Button5Click
    end
  end
  object GroupBox2: TGroupBox
    Left = 584
    Top = 48
    Width = 249
    Height = 329
    Caption = ' Information '
    TabOrder = 3
    object Label1: TLabel
      Left = 128
      Top = 40
      Width = 33
      Height = 13
      Caption = 'Label1'
    end
    object Label2: TLabel
      Left = 128
      Top = 56
      Width = 33
      Height = 13
      Caption = 'Label2'
    end
    object Label3: TLabel
      Left = 128
      Top = 112
      Width = 33
      Height = 13
      Caption = 'Label3'
    end
    object Label4: TLabel
      Left = 128
      Top = 128
      Width = 33
      Height = 13
      Caption = 'Label4'
    end
    object Label6: TLabel
      Left = 128
      Top = 144
      Width = 33
      Height = 13
      Caption = 'Label6'
    end
    object Label7: TLabel
      Left = 16
      Top = 176
      Width = 86
      Height = 13
      Caption = 'Audio-Channels:'
    end
    object Label8: TLabel
      Left = 128
      Top = 176
      Width = 33
      Height = 13
      Caption = 'Label8'
    end
    object Label10: TLabel
      Left = 16
      Top = 40
      Width = 73
      Height = 13
      Caption = 'Good Packets:'
    end
    object Label11: TLabel
      Left = 16
      Top = 56
      Width = 63
      Height = 13
      Caption = 'Bad Packets:'
    end
    object Label12: TLabel
      Left = 16
      Top = 112
      Width = 72
      Height = 13
      Caption = 'Write-Pointer:'
    end
    object Label13: TLabel
      Left = 16
      Top = 128
      Width = 70
      Height = 13
      Caption = 'Read-Pointer:'
    end
    object Label14: TLabel
      Left = 16
      Top = 144
      Width = 92
      Height = 13
      Caption = 'Buffered Samples:'
    end
    object Label15: TLabel
      Left = 16
      Top = 24
      Width = 60
      Height = 13
      Caption = 'Packet-Size:'
    end
    object Label16: TLabel
      Left = 128
      Top = 24
      Width = 39
      Height = 13
      Caption = 'Label16'
    end
    object Label17: TLabel
      Left = 16
      Top = 192
      Width = 67
      Height = 13
      Caption = 'Sample-Rate:'
    end
    object Label18: TLabel
      Left = 128
      Top = 192
      Width = 39
      Height = 13
      Caption = 'Label18'
    end
    object Label19: TLabel
      Left = 16
      Top = 72
      Width = 82
      Height = 13
      Caption = 'Packet-Counter:'
    end
    object Label20: TLabel
      Left = 128
      Top = 72
      Width = 39
      Height = 13
      Caption = 'Label20'
    end
    object Label21: TLabel
      Left = 16
      Top = 88
      Width = 63
      Height = 13
      Caption = 'Packet-Rate:'
    end
    object Label22: TLabel
      Left = 128
      Top = 88
      Width = 39
      Height = 13
      Caption = 'Label22'
    end
    object packeterror: TLabel
      Left = 16
      Top = 256
      Width = 217
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = '...'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGreen
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object packetmissed: TLabel
      Left = 16
      Top = 280
      Width = 217
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = '...'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGreen
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object packetmisordered: TLabel
      Left = 16
      Top = 304
      Width = 217
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = '...'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGreen
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label23: TLabel
      Left = 16
      Top = 240
      Width = 71
      Height = 13
      Caption = 'Signal health:'
    end
    object Label25: TLabel
      Left = 16
      Top = 208
      Width = 101
      Height = 13
      Caption = 'Samples per Packet:'
    end
    object Label27: TLabel
      Left = 128
      Top = 208
      Width = 39
      Height = 13
      Caption = 'Label27'
    end
    object Button8: TButton
      Left = 200
      Top = 304
      Width = 41
      Height = 17
      Caption = 'Reset'
      TabOrder = 0
      OnClick = Button8Click
    end
  end
  object GroupBox3: TGroupBox
    Left = 584
    Top = 384
    Width = 249
    Height = 89
    Caption = ' Advanced options '
    TabOrder = 4
    object useUdpData: TCheckBox
      Left = 8
      Top = 24
      Width = 161
      Height = 17
      Caption = 'Play received audio'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
  end
  object GroupBox4: TGroupBox
    Left = 392
    Top = 48
    Width = 185
    Height = 153
    Caption = ' Record control '
    TabOrder = 5
    object Label9: TLabel
      Left = 8
      Top = 16
      Width = 100
      Height = 13
      Caption = 'Record to filename:'
    end
    object Edit1: TEdit
      Left = 8
      Top = 32
      Width = 169
      Height = 21
      TabOrder = 0
      Text = 'c:\Temp\Test.wav'
    end
    object recordformat: TRadioGroup
      Left = 8
      Top = 80
      Width = 97
      Height = 57
      Caption = ' Record format '
      ItemIndex = 1
      Items.Strings = (
        '16bit PCM'
        '32bit PCM')
      TabOrder = 1
    end
    object Button6: TButton
      Left = 112
      Top = 80
      Width = 65
      Height = 25
      Caption = 'Record'
      TabOrder = 2
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 112
      Top = 112
      Width = 65
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = Button7Click
    end
  end
  object transmissioncontrol: TGroupBox
    Left = 200
    Top = 48
    Width = 185
    Height = 153
    Caption = ' Transmission control '
    TabOrder = 6
    object Label24: TLabel
      Left = 8
      Top = 24
      Width = 120
      Height = 13
      Caption = 'Audio-Buffer (Samples):'
    end
    object audiobufferedit: TEdit
      Left = 8
      Top = 40
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '16384'
    end
  end
  object udpserver: TIdUDPServer
    Bindings = <>
    DefaultPort = 4023
    OnUDPRead = udpserverUDPRead
    Left = 576
    Top = 8
  end
  object Timer1: TTimer
    Interval = 150
    OnTimer = Timer1Timer
    Left = 576
    Top = 64
  end
  object audioout: TAudioOut
    FrameRate = 48000
    Stereo = True
    WaveDevice = 0
    OnFillBuffer = audiooutFillBuffer
    Left = 608
    Top = 8
  end
  object Timer2: TTimer
    Interval = 5000
    OnTimer = Timer2Timer
    Left = 608
    Top = 64
  end
end
