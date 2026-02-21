import '../models/glossary_term.dart';

const List<GlossaryTerm> kGlossaryTerms = [
  GlossaryTerm(
    id: 'T01',
    title: '종소세',
    description:
        '1년간 벌어들인 모든 소득(사업·근로·연금 등)을 합산해서 매기는 세금이에요. 매년 5월에 전년도분을 신고·납부해요.',
    category: '종소세',
    whereToFind: ['홈택스 → 종합소득세 → 신고내역 조회', '손택스 앱 → 종합소득세 신고'],
  ),
  GlossaryTerm(
    id: 'T02',
    title: '지방소득세',
    description: '종합소득세의 10%를 지방자치단체에 추가로 내는 세금이에요. 종소세와 함께 자동 계산돼요.',
    category: '종소세',
    whereToFind: ['종소세 신고 완료 후 위택스에서 별도 신고', '홈택스 신고서 하단 \'지방소득세\' 항목'],
  ),
  GlossaryTerm(
    id: 'T03',
    title: '총세금(결정)',
    description: '모든 공제·감면을 반영한 후 최종 확정된 세금이에요. 이 앱에서는 종소세+지방소득세를 합산해서 보여줘요.',
    category: '종소세',
    whereToFind: ['홈택스 신고서 → \'결정세액\' 항목'],
  ),
  GlossaryTerm(
    id: 'T04',
    title: '기납부세액',
    description:
        '1년 동안 원천징수·중간예납 등으로 이미 낸 세금의 합계예요. 정확히 입력할수록 추가 납부/환급 예측이 맞아져요.',
    category: '기납부',
    whereToFind: ['원천징수영수증 → \'결정세액\' 란', '홈택스 → My홈택스 → 납부내역 조회'],
  ),
  GlossaryTerm(
    id: 'T05',
    title: '추가/환급',
    description: '확정된 총세금에서 이미 낸 세금(기납부)을 뺀 금액이에요. 양수면 추가 납부, 음수면 환급받을 수 있어요.',
    category: '기납부',
    whereToFind: ['앱이 자동 계산해요. 기납부세액을 정확히 입력하면 결과가 더 정확해져요.'],
  ),
  GlossaryTerm(
    id: 'T06',
    title: '총소득',
    description: '사업·근로·연금·금융·기타소득을 모두 합한 금액이에요. 해당하는 소득만 체크하면 자동으로 합산돼요.',
    category: '소득',
    whereToFind: ['각 소득 항목별 원천징수영수증이나 지급명세서를 모아서 확인해요.'],
  ),
  GlossaryTerm(
    id: 'T07',
    title: '사업소득',
    description:
        '음식점·카페·프리랜서 등 사업으로 벌어들인 소득이에요. 매출에서 필요경비를 빼서 계산해요. 종소세에서는 VAT를 제외한 매출을 기준으로 해요.',
    category: '소득',
    whereToFind: [
      '홈택스 → 전자세금계산서 조회',
      '카드매출: 여신금융협회 가맹점 매출 조회',
      '현금영수증: 홈택스 → 현금영수증 발급내역',
    ],
  ),
  GlossaryTerm(
    id: 'T08',
    title: '필요경비',
    description:
        '사업을 위해 쓴 비용(임차료·재료비·인건비 등)이에요. 경비가 많을수록 소득금액이 줄어 세금이 낮아져요. 부가세 매입과는 범위가 다를 수 있어요.',
    category: '소득',
    whereToFind: ['사업용 신용카드 사용내역', '세금계산서·영수증·임대차계약서 등 증빙서류'],
  ),
  GlossaryTerm(
    id: 'T09',
    title: '소득금액',
    description: '총수입에서 필요경비를 뺀 금액이에요. 여기에 소득공제를 적용한 뒤 세율이 매겨져요.',
    category: '소득',
    whereToFind: ['홈택스 신고서 → \'소득금액\' 항목'],
  ),
  GlossaryTerm(
    id: 'T10',
    title: '과세표준',
    description: '소득금액에서 각종 소득공제를 뺀 금액이에요. 이 금액을 기준으로 세율 구간이 정해져요.',
    category: '종소세',
    whereToFind: ['홈택스 신고서 → \'과세표준\' 항목'],
  ),
  GlossaryTerm(
    id: 'T11',
    title: '누진세율',
    description:
        '과세표준이 높을수록 세율도 올라가는 구조예요(6%~45%). 구간별로 나눠서 계산하기 때문에 전체에 최고세율이 적용되지는 않아요.',
    category: '종소세',
    whereToFind: ['국세청 세율표 참고', '앱이 누진공제 방식으로 자동 계산해요.'],
  ),
  GlossaryTerm(
    id: 'T12',
    title: '산출세액',
    description: '과세표준에 누진세율을 적용해서 나온 세금이에요. 여기서 세액공제를 빼면 최종 결정세액이 돼요.',
    category: '종소세',
    whereToFind: ['홈택스 신고서 → \'산출세액\' 항목'],
  ),
  GlossaryTerm(
    id: 'T13',
    title: '소득공제',
    description: '세율을 적용하기 전 단계에서 소득금액을 줄여주는 공제예요. 인적공제·노란우산공제 등이 대표적이에요.',
    category: '공제',
    whereToFind: ['홈택스 신고서 → \'소득공제\' 항목'],
  ),
  GlossaryTerm(
    id: 'T14',
    title: '세액공제',
    description:
        '이미 계산된 세금에서 직접 빼주는 공제예요. 10만 원 공제되면 세금이 10만 원 줄어들어요. 연금계좌 세액공제 등이 있어요.',
    category: '공제',
    whereToFind: ['홈택스 신고서 → \'세액공제\' 항목'],
  ),
  GlossaryTerm(
    id: 'T15',
    title: '인적공제',
    description: '본인과 부양가족 수에 따라 소득에서 빼주는 공제예요. 기본공제 1인당 150만 원이에요.',
    category: '공제',
    whereToFind: ['홈택스 신고 → 인적공제 입력 단계', '주민등록등본으로 부양가족 확인'],
  ),
  GlossaryTerm(
    id: 'T16',
    title: '노란우산',
    description:
        '소기업·소상공인 공제로, 매월 납입한 금액을 소득에서 공제받아요. 사업소득 4,000만 원 이하는 최대 600만 원, 4,000만~1억 원은 400만 원, 1억 원 초과는 200만 원까지 공제돼요.',
    category: '공제',
    whereToFind: ['노란우산공제 홈페이지 또는 앱 → 납입내역 조회', '중소기업중앙회 납입증명서'],
  ),
  GlossaryTerm(
    id: 'T17',
    title: '근로소득',
    description: '직장에서 급여로 받는 소득이에요. 사업소득과 함께 하는 경우(N잡) 종소세 신고 때 합산돼요.',
    category: '소득',
    whereToFind: ['회사에서 발급하는 근로소득 원천징수영수증', '홈택스 → My홈택스 → 지급명세서 조회'],
  ),
  GlossaryTerm(
    id: 'T18',
    title: '원천징수',
    description:
        '소득을 지급받을 때 미리 떼인 세금이에요. 이 금액이 기납부세액에 포함되어 추가 납부/환급 계산에 직접 영향을 줘요.',
    category: '기납부',
    whereToFind: ['원천징수영수증 → \'결정세액\' 또는 \'기납부세액\' 란', '홈택스 → My홈택스 → 지급명세서'],
  ),
  GlossaryTerm(
    id: 'T19',
    title: '중간예납',
    description:
        '전년도 종소세의 절반을 11월에 미리 내는 제도예요. 납부한 금액이 있으면 기납부세액에 포함되어 추가 납부액이 줄어들어요.',
    category: '기납부',
    whereToFind: ['중간예납 고지서', '홈택스 → My홈택스 → 납부내역 조회'],
  ),
  GlossaryTerm(
    id: 'T20',
    title: '금융 과세',
    description:
        '이자·배당 등 금융소득이 연 2,000만 원을 넘으면 다른 소득과 합산과세돼요. 2,000만 원 이하는 원천징수(15.4%)로 분리과세돼요.',
    category: '소득',
    whereToFind: ['은행·증권사 → 연간 이자/배당 내역 조회', '홈택스 → My홈택스 → 금융소득 조회'],
  ),
  GlossaryTerm(
    id: 'T21',
    title: '귀속연도',
    description:
        '소득이 실제로 발생한 연도를 말해요. 2025년에 번 소득은 귀속연도 2025년이고, 2026년 5월에 신고·납부해요.',
    category: '종소세',
    whereToFind: ['홈택스 종소세 신고 시 \'귀속연도\' 선택 항목'],
  ),
  GlossaryTerm(
    id: 'T22',
    title: '정밀도',
    description:
        '입력한 항목이 얼마나 정확한지를 나타내는 점수예요. 직접 입력한 값이 많을수록 높고, 추정·미입력이 많을수록 낮아져요.',
    category: '정밀도',
    whereToFind: ['앱 결과 화면 상단의 정밀도 게이지에서 확인해요.'],
  ),
  GlossaryTerm(
    id: 'T23',
    title: '추정',
    description:
        '\'모르겠어요\'를 선택하면 앱이 평균값으로 대신 채워주는 값이에요. 실제와 차이가 있을 수 있어서 정밀도가 낮아져요.',
    category: '정밀도',
    whereToFind: ['입력 항목에서 \'추정\' 배지가 붙은 값이 해당돼요.'],
  ),
  GlossaryTerm(
    id: 'T24',
    title: '기장신고',
    description:
        '장부에 기록된 실제 매출과 경비를 기반으로 신고하는 방식이에요. 단순경비율 방식보다 정확하고, 세금이 유리할 수 있어요.',
    category: '소득',
    whereToFind: ['홈택스 신고 시 \'간편장부\' 또는 \'복식부기\' 선택'],
  ),
  GlossaryTerm(
    id: 'T25',
    title: '단순경비율',
    description:
        '실제 경비 대신 국세청이 업종별로 정한 비율로 경비를 추정하는 방식이에요. 장부가 없을 때 간편하지만, 실제보다 불리할 수 있어요.',
    category: '소득',
    whereToFind: ['국세청 고시 단순경비율표 참고', '홈택스 신고 시 \'추계신고-단순경비율\' 선택'],
  ),
  GlossaryTerm(
    id: 'T26',
    title: '분리과세',
    description:
        '다른 소득과 합산하지 않고 별도의 세율로 과세가 끝나는 방식이에요. 금융소득 2,000만 원 이하 등이 해당돼요.',
    category: '소득',
    whereToFind: ['해당 소득의 원천징수로 납세 종결'],
  ),
  GlossaryTerm(
    id: 'T27',
    title: '종합과세',
    description:
        '여러 소득을 합산해서 누진세율로 과세하는 방식이에요. 금융소득이 연 2,000만 원을 넘으면 종합과세 대상이 돼요.',
    category: '소득',
    whereToFind: ['홈택스 종소세 신고 시 자동 판정'],
  ),
  GlossaryTerm(
    id: 'T28',
    title: '증빙',
    description:
        '소득이나 지출 금액을 증명하는 서류(영수증·세금계산서·원천징수영수증 등)예요. 증빙이 있으면 가장 정확하게 입력할 수 있어요.',
    category: '기타',
    whereToFind: ['카드매출전표, 현금영수증, 세금계산서, 원천징수영수증 등'],
  ),
  GlossaryTerm(
    id: 'T29',
    title: '최신성',
    description:
        '입력한 자료가 얼마나 최근에 업데이트됐는지에 대한 점수예요. 오래된 자료로 계산하면 실제 세금과 차이가 커질 수 있어요.',
    category: '정밀도',
    whereToFind: ['자료함 화면 하단의 \'마지막 업데이트\'', '홈 화면 정확도 게이지의 \'최신성\' 항목'],
  ),
  GlossaryTerm(
    id: 'T30',
    title: '일몰 조항',
    description:
        '세금 혜택이 특정 날짜까지만 적용되는 한시적 규정이에요. 기한이 지나면 원래 비율로 돌아가요. 세금레이더는 날짜에 따라 자동으로 적용 여부를 판단해요.',
    category: '기타',
    whereToFind: [
      '기획재정부 → 세법개정안',
      '국세청 → 달라지는 세금제도',
      '세금레이더 → 용어 사전 → 우대한도율, 9/109 특례',
    ],
  ),
  GlossaryTerm(
    id: 'V01',
    title: '부가세',
    description:
        '물건이나 서비스를 팔 때 붙는 10% 세금이에요. 1기(1~6월)와 2기(7~12월)로 나눠 반기마다 신고·납부해요.',
    category: '부가세',
    whereToFind: ['홈택스 → 부가가치세 → 신고내역 조회', '손택스 앱 → 부가세 신고'],
  ),
  GlossaryTerm(
    id: 'V02',
    title: '납부세액',
    description: '이번 반기에 실제로 납부해야 하는 부가세 금액이에요. 매입이 매출보다 많으면 환급받을 수도 있어요.',
    category: '부가세',
    whereToFind: ['홈택스 부가세 신고서 → \'납부(환급)세액\' 항목'],
  ),
  GlossaryTerm(
    id: 'V03',
    title: '매출세액',
    description: '매출에 포함된 부가세예요. VAT 포함 매출의 경우 매출 ÷ 11로 계산돼요.',
    category: '부가세',
    whereToFind: ['홈택스 → 전자세금계산서 매출 조회', '카드매출 합계 확인'],
  ),
  GlossaryTerm(
    id: 'V04',
    title: '매입세액',
    description: '사업 관련 지출에 포함된 부가세예요. 세금계산서를 받은 매입분이 공제되어 납부세액이 줄어들어요.',
    category: '부가세',
    whereToFind: ['홈택스 → 전자세금계산서 매입 조회', '사업용 신용카드 매입 내역'],
  ),
  GlossaryTerm(
    id: 'V05',
    title: '의제매입',
    description:
        '면세 농산물 등을 구입하면 매입세액의 일부를 공제받을 수 있어요. 음식점은 우대한도율(60~75%)과 공제율(8/108 또는 9/109)이 적용되며, 한도율과 공제율은 과세표준과 업종에 따라 달라요.',
    category: '부가세',
    whereToFind: ['부가세 신고서 → \'의제매입세액공제\' 란', '홈택스 → 부가가치세 신고 → 의제매입세액 공제신고서', '면세계산서·영수증 합계표'],
  ),
  GlossaryTerm(
    id: 'V06',
    title: '신카 공제',
    description:
        '신용카드·현금영수증 발행 금액의 1.3%를 세액에서 공제받아요(연간 한도 1,000만 원). 이 혜택은 2026년 12월 31일까지 적용되며, 이후에는 1.0%, 연간 500만 원 한도로 축소돼요.',
    category: '부가세',
    whereToFind: ['카드매출 + 현금영수증 발행 합계 확인'],
  ),
  GlossaryTerm(
    id: 'V07',
    title: '과세기간',
    description:
        '부가세를 계산하는 기간 단위예요. 1기(1~6월, 7월 신고)와 2기(7~12월, 다음 해 1월 신고)로 나뉘어요.',
    category: '부가세',
    whereToFind: ['앱에서 자동으로 현재 과세기간을 판단해요.'],
  ),
  GlossaryTerm(
    id: 'V08',
    title: 'VAT 포함',
    description:
        '입력하는 매출 금액에 부가세(10%)가 포함되어 있는지 여부예요. 소비자에게 받는 가격은 보통 VAT 포함이에요.',
    category: '부가세',
    whereToFind: ['메뉴판/영수증의 가격이 VAT 포함인지 확인'],
  ),
  GlossaryTerm(
    id: 'V09',
    title: '예정고지',
    description:
        '국세청이 직전 반기 확정 납부세액의 50%를 고지서로 보내주는 제도예요. 사업자가 직접 신고할 필요 없이 고지된 금액만 납부하면 돼요. 개인 일반사업자는 4월(1기)·10월(2기)에 받아요.',
    category: '부가세',
    whereToFind: [
      '국세청에서 우편/전자고지 발송',
      '홈택스 → My홈택스 → 고지/체납 내역 조회',
    ],
  ),
  GlossaryTerm(
    id: 'V10',
    title: '확정신고',
    description:
        '반기(6개월) 동안의 실제 매출·매입 자료를 직접 홈택스에 신고하고 세금을 납부하는 절차예요. 이미 낸 예정고지 세액은 차감돼요. 7월(1기)·다음 해 1월(2기)에 신고해요.',
    category: '부가세',
    whereToFind: [
      '홈택스 → 부가가치세 → 일반과세자 확정신고',
      '세무사 대리 신고 시 자료 전달 필요',
    ],
  ),
  GlossaryTerm(
    id: 'V11',
    title: '우대한도율',
    description:
        '의제매입세액공제의 한도를 높여주는 우대 비율이에요. 음식점 개인사업자는 과세표준에 따라 60~75%까지 적용돼요(2027년 12월 31일까지). 이후에는 기본한도율(40~50%)로 돌아가요.',
    category: '부가세',
    whereToFind: [
      '부가가치세법 시행령 제84조',
      '국세청 → 의제매입세액 공제 안내',
      '세금레이더 → 부가세 상세 → 의제매입 공제 항목',
    ],
  ),
  GlossaryTerm(
    id: 'V12',
    title: '9/109 특례',
    description:
        '연 과세표준 4억 원 이하 음식점에 적용되는 의제매입세액 공제율 특례예요. 일반 공제율(8/108)보다 높은 9/109를 적용받아요. 2026년 12월 31일까지 한시적으로 적용돼요.',
    category: '부가세',
    whereToFind: [
      '부가가치세법 시행령 제84조',
      '국세청 → 의제매입세액 공제율 안내',
      '세금레이더 → 부가세 상세 → 의제매입 공제율',
    ],
  ),
];

final Map<String, GlossaryTerm> kGlossaryTermMap = {
  for (final term in kGlossaryTerms) term.id: term,
};
