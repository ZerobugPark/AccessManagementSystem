
## 프로젝트 소개
"Access Management System"은 Bluetooth 기반 출입 관리 시스템입니다.  
Arduino MCU와 iOS 애플리케이션이 실시간 BLE 통신을 통해 사용자의 출입 상태를 제어합니다.  
AES128(CBC) 암호화를 적용해 안전한 인증 과정을 제공하며, 출입 로그를 실시간으로 기록합니다.


<br>

## 프로젝트 정보

### 기술 스택
- **FrameWork** - SwfitUI, Combine,CoreBluetooth, Swift Data
- **Architecture** - MVVM
- **MCU**: 아두이노 MEGA 2560
- **Bluetooth Version**: v4.0 (BLE)
  
<br>

### 기술 설명
- **최소 지원 iOS 버전**: iOS 26.0
- **통신 방식**: Bleutooth Low Energy(BLE) 기반 실시간 출입 제어 및 데이터 송수신
- **데이터 암호화**: AES-128 CBC + Base64 인코딩으로 데이터 내용을 보호
- **보안 설계**:
  - 전송 데이터는 AES 암호화를 통해 보호되며, BLE 채널 자체는 암호화 X
  - 페어링된 기기만이 인증된 출입 요청을 전송 가능
- **백그라운드 동작**:
  - 앱이 백그라운드 상태에서도 BLE 광고(Advertisement)를 지속적으로 스캔
  - 주변 기기의 RSSI(신호 세기)를 기반으로 등록된 장치를 자동 감지 및 페어링
- **로그 기능**: 사용자 출입 기록 로그 관리  
    
<br><br>


## 하드웨어 구성도

### 하드웨어 구성요소
- **MCU**: 아두이노 MEGA 2560
- **블루투스 모듈**: HM-10(Bluetooth v4.0)
- **서보모터(Door 제어)**: – SG90
- **OLED Display**
- **Switch**: 사용자 등록 스위치


<table>
  <tr>
    <td align="center" valign="top">
      <b>하드웨어 환경구축</b><br>
      <img src="https://github.com/user-attachments/assets/0f574ac7-d510-43f0-9dfc-04013a4b3c29" width="300"/>
    </td>
    <td align="center" valign="top">
      <b>배선도</b><br>
      <img src="https://github.com/user-attachments/assets/43af8337-45f7-4023-9f2e-5fdc45bc3e09" width="600"/>
    </td>
  </tr>
</table>

<br><br>

## 페이지별 기능


### [블루투스 자동 및 백그라운드 연결]

- RSSI 기반 자동 연결(-60 dBm 이상에서 연결, HM-10 모듈 테스트 시 약 10cm)
- 자동 연결 시에는 암호화용 신규 IV(초기화 벡터) 갱신
- 블루투스 연결 이후에 승인 시 문이 열리며, 30초 이내에 출퇴근 등록
- 백그라운드 상태에서도 RSSI -60dBM 내에 등록된 기기가 있을 경우 자동 연결 및 푸시 알림
- MCU는 미연결 상태에서 지속적으로 광고를 송출하여 중앙 장치가 자동으로 탐지하도록 구현
- 출입 로그 확인
- 블루투스 연결 이후, 별도의 출근 또는 퇴근 미입력 상태에서 RSSI -90dBM 이상일 경우 자동 해제 
(ex. 태그가 되었지만, 전화 등의 이유로 출근 또는 퇴근을 입력하지 못하는 경우 해제될 때 까지 기다리는 것이 아닌 RSSI 감도 기반 해제)

<table>
  <tr>
    <td align="center" valign="top">
      <b>블루투스 자동 연결</b><br>
      <img src="https://github.com/user-attachments/assets/85d9aa70-5938-4ebc-a276-ea9fe6c50c81" width="350"/>
    </td>
    <td align="center" valign="center">
      <b>iOS <-> 출입관리시스템 자동 연결 플로우 차트</b><br>
      <img src="https://github.com/user-attachments/assets/e366fc21-c6bb-4dc6-8e85-551a4ac6a5ac" width="550"/>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td align="center" valign="top">
      <b>백그라운드 상태 연결</b><br>
      <img src="https://github.com/user-attachments/assets/ffce40d7-4ef8-4490-ad00-3cf82abb3d7b" width="291"/>
    </td>
    <td align="center" valign="top">
      <b>RSSI 감도 기반 연결 해제 </b><br>
      <img src="https://github.com/user-attachments/assets/b573fbc7-0d71-4669-b7d6-0107c998e741" width="291"/>
    </td>
    <td align="center" valign="top">
      <b>iOS <-> 기록 관리 </b><br>
      <img src="https://github.com/user-attachments/assets/17e38914-00e3-4dcd-81fb-97ac1e645bb7" width="291"/>
    </td>
  </tr>
</table>




    

<br><br>

### [사용자 및 카드 등록]

- 카드 ID 암호화 알고리즘AES128 (CBC) 적용
- IV(초기화 벡터) - 등록 IV는 iOS 및 MUC 고정 값
- 시크릿 키 고정
- 패딩 방식: PKCS#7 패딩 적용 (블록 크기 단위 맞춤)

<table>
  <tr>
    <td align="center" valign="top">
      <b>사용자 및 카드 등록</b><br>
      <img src="https://github.com/user-attachments/assets/f5be3ab4-8946-43e0-b3ac-52084e36692a" width="350"/>
    </td>
    <td align="center" valign="center">
      <b>iOS <-> 출입관리시스템 등록 플로우 차트</b><br>
      <img src="https://github.com/user-attachments/assets/0754efcf-3c45-4ec7-8410-fc1fa0c07762" width="550"/>
    </td>
  </tr>
</table>





<br><br>












