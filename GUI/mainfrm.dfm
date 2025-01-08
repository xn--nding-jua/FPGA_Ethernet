object mainform: Tmainform
  Left = 883
  Top = 472
  BorderStyle = bsSingle
  Caption = 'UdpAudioTest'
  ClientHeight = 297
  ClientWidth = 658
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
  object packeterror: TLabel
    Left = 328
    Top = 272
    Width = 313
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
  object channelselector_left: TRadioGroup
    Left = 8
    Top = 176
    Width = 193
    Height = 89
    Caption = ' Channel Selector Left '
    ItemIndex = 0
    Items.Strings = (
      'Channel 1'
      'Channel 2')
    TabOrder = 0
  end
  object channelselector_right: TRadioGroup
    Left = 208
    Top = 176
    Width = 185
    Height = 89
    Caption = ' Channel Selector Right '
    ItemIndex = 1
    Items.Strings = (
      'Channel 1'
      'Channel 2')
    TabOrder = 1
  end
  object useUdpData: TCheckBox
    Left = 16
    Top = 272
    Width = 217
    Height = 17
    Caption = 'Play Audio-Samples received via UDP'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 48
    Width = 385
    Height = 121
    Caption = ' General Control '
    TabOrder = 3
    object Label9: TLabel
      Left = 256
      Top = 16
      Width = 49
      Height = 13
      Caption = 'Filename:'
    end
    object Button1: TButton
      Left = 16
      Top = 24
      Width = 137
      Height = 25
      Caption = 'Enable UDP Server'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 16
      Top = 56
      Width = 137
      Height = 25
      Caption = 'Send HELLO to FPGA'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button4: TButton
      Left = 16
      Top = 88
      Width = 137
      Height = 25
      Caption = 'Stop server and file'
      TabOrder = 2
      OnClick = Button4Click
    end
    object Button3: TButton
      Left = 160
      Top = 56
      Width = 89
      Height = 25
      Caption = 'Start Audio'
      TabOrder = 3
      OnClick = Button3Click
    end
    object Button5: TButton
      Left = 160
      Top = 88
      Width = 89
      Height = 25
      Caption = 'Stop Audio'
      TabOrder = 4
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 256
      Top = 56
      Width = 113
      Height = 25
      Caption = 'Start Recording'
      TabOrder = 5
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 256
      Top = 88
      Width = 113
      Height = 25
      Caption = 'Stop Recording'
      TabOrder = 6
      OnClick = Button7Click
    end
    object Edit1: TEdit
      Left = 256
      Top = 32
      Width = 113
      Height = 21
      TabOrder = 7
      Text = 'c:\Temp\Test.raw'
    end
  end
  object GroupBox2: TGroupBox
    Left = 400
    Top = 48
    Width = 249
    Height = 217
    Caption = ' Information '
    TabOrder = 4
    object Label1: TLabel
      Left = 120
      Top = 40
      Width = 33
      Height = 13
      Caption = 'Label1'
    end
    object Label2: TLabel
      Left = 120
      Top = 56
      Width = 33
      Height = 13
      Caption = 'Label2'
    end
    object Label3: TLabel
      Left = 120
      Top = 112
      Width = 33
      Height = 13
      Caption = 'Label3'
    end
    object Label4: TLabel
      Left = 120
      Top = 128
      Width = 33
      Height = 13
      Caption = 'Label4'
    end
    object Label6: TLabel
      Left = 120
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
      Left = 120
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
      Left = 120
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
      Left = 120
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
      Left = 120
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
      Left = 120
      Top = 88
      Width = 39
      Height = 13
      Caption = 'Label22'
    end
  end
  object Button8: TButton
    Left = 232
    Top = 272
    Width = 89
    Height = 17
    Caption = 'Reset Counter'
    TabOrder = 5
    OnClick = Button8Click
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
