-- All expense report
SELECT 
  ppnf.list_name AS "Full Name",
  ppnfs.list_name AS "Manage Name",
  papf.person_number AS "Employee Number",
  (
    SELECT DECODE(meaning, 'Paid', 'Y', 'N')
    FROM fnd_lookups
    WHERE lookup_type = 'EXM_REPORT_STATUS'
    AND lookup_code = eer.expense_status_code
  ) AS "Workflow Approved Flag",
 TO_CHAR(eer.REPORT_SUBMIT_DATE, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=AMERICAN') AS "WEEK END DATE",
 eer.OBJECT_VERSION_NUMBER AS "VOUCHER NUMBER", --prev ee.sequence_num
 (eer.EXPENSE_REPORT_NUM ) AS "Invoice Number",
  nvl(TO_CHAR(eer.CREATION_DATE, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=AMERICAN'),TO_CHAR(ect.CREATION_DATE, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=AMERICAN')) AS "Creation Date",
  ee.expense_source AS "Source",
  SUBSTR(ee.DESCRIPTION, 1, 100) AS EXPENSE_DESCRIPTION,
  eet.description AS "EX TYPE DESC",
  nvl(eer.REIMBURSEMENT_CURRENCY_CODE, ect.POSTED_CURRENCY_CODE) AS "Currency Code",
     nvl(eed.REIMBURSABLE_AMOUNT,ect.posted_amount) AS AMOUNT,
     ee.justification AS "Justification",
  Ee.merchant_name AS "Merchant Name",
  ee.RECEIPT_VERIFIED_FLAG AS "Receipt Verified Flag",
  ee.RECEIPT_MISSING_FLAG AS "Receipt Missing Flag",
  (
    SELECT LISTAGG(name, ',') WITHIN GROUP (ORDER BY name)
    FROM exm_expense_Attendees
    WHERE expense_id = ee.expense_id
    GROUP BY expense_id
  ) AS "Attendees Names",
   ee.destination_from AS "Destination From",
  ee.destination_to AS "Destination To",
  ee.trip_distance AS "Trip Distance",
  ect.reference_number AS "CC Trx Id",
  TO_CHAR(NVL(gcc.segment1,GCP.segment1)) SEGMENT1,
  TO_CHAR(NVL(gcc.segment2,gcp.segment2)) SEGMENT2,
  TO_CHAR(NVL(gcc.segment3,gcp.segment3)) SEGMENT3,
  TO_CHAR(NVL(gcc.segment4,gcp.segment4)) SEGMENT4,
  TO_CHAR(NVL(gcc.segment5,gcp.segment5)) SEGMENT5,
  TO_CHAR(NVL(gcc.segment6,gcp.segment6)) SEGMENT6,
  TO_CHAR(NVL(gcc.segment7,gcp.segment7)) SEGMENT7,
  TO_CHAR(NVL(gcc.segment8,gcp.segment8)) SEGMENT8,
  TO_CHAR(NVL(gcc.segment9,gcp.segment9)) SEGMENT9,
  TO_CHAR(NVL(gcc.segment10,gcp.segment10)) SEGMENT10,
  (select TO_CHAR(prj.SEGMENT1)from pjf_projects_all_b prj where eed.pjc_project_id = prj.project_id) Project_number,
  (select TO_CHAR(PTV.TASK_NUMBER)from pjf_projects_all_b prj,PJF_TASKS_V PTV
  where eed.pjc_project_id = prj.project_id
  AND prj.PROJECT_ID=PTV.PROJECT_ID
  AND eed.PJC_TASK_ID = PTV.Task_id) Task_number,
  (select EXPENDITURE_TYPE_NAME from PJF_EXP_TYPES_TL 
  where EXPENDITURE_TYPE_ID = eed.PJC_EXPENDITURE_TYPE_ID) EXPENDITURE_TYPE,
  (select hou.name from hr_all_organization_units hou where hou.organization_id = eed.PJC_ORGANIZATION_ID) Expense_Organization,
  ee.number_of_attendees AS "Number Of People",
  case when ee.expense_source = 'CASH' then
	nvl(TO_CHAR(aia.GL_DATE, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=AMERICAN'),TO_CHAR(eer.EXPENSE_REPORT_DATE, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=AMERICAN')) 
  when ee.expense_source = 'CREDIT_CARD' then
	TO_CHAR(ect.transaction_date, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=AMERICAN')
  end AS "GL Date",
 nvl((
    SELECT meaning
    FROM fnd_lookups
    WHERE lookup_type = 'EXM_REPORT_STATUS'
    AND lookup_code = eer.expense_status_code 
  ),'Transaction Not in Report') AS "Expense Status Code" ,
 ECT.COMPANY_NUMBER,
(select COMPANY_ACCOUNT_NAME from EXM_CC_COMPANY_ACCOUNTS ECA 
		  where ECA.CARD_PROGRAM_ID = ECT.CARD_PROGRAM_ID
			AND ECA.CC_COMPANY_ACCOUNT_ID     = ECT.COMPANY_ACCOUNT_ID) COMPANY_ACCOUNT_NAME,
(SELECT
    pernames.full_name	
FROM
    HR_ORGANIZATION_INFORMATION_F orgInfo,
    PER_ALL_PEOPLE_F p,
    PER_PERSON_NAMES_F pernames,
	HR_ORGANIZATION_UNITS_F_TL houft
WHERE
    orgInfo.ORG_INFORMATION_CONTEXT = 'PER_GL_COST_CENTER_INFO'
    AND TRUNC(SYSDATE) BETWEEN orgInfo.effective_start_date AND orgInfo.effective_end_date
    AND orgInfo.ORG_INFORMATION6 = p.person_id (+)
    AND p.person_id = pernames.person_id (+)
    AND TRUNC(SYSDATE) BETWEEN NVL(p.effective_start_date,sysdate-1) AND nvl(p.effective_end_date,sysdate+1)
    AND TRUNC(SYSDATE) BETWEEN nvl(pernames.effective_start_date,sysdate-1) AND nvl(pernames.effective_end_date,sysdate+1)
    AND NVL(pernames.name_type,'GLOBAL') = 'GLOBAL'
	AND houft.language = 'US'
	AND houft.organization_id = orgInfo.organization_id
	AND orgInfo.ORG_INFORMATION1 = gcp.segment2
	--AND houft.name = 'ELECTRIC METER SHOP'
    AND TRUNC(sysdate) BETWEEN houft.EFFECTIVE_START_DATE AND houft.EFFECTIVE_END_DATE
	AND ROWNUM = 1) Cost_center_Manager,
gcp.segment2 Employee_CostCenter	
FROM
	EXM_EXPENSES ee,
	EXM_EXPENSE_REPORTS eer,
	EXM_EXPENSE_DISTS eed,
	EXM_EXPENSE_TYPES eet,
	EXM_CREDIT_CARD_TRXNS ect,
	AP_INVOICES_ALL aia,
	--IBY_DOCS_PAYABLE_ALL idpa,
	--IBY_PAYMENTS_ALL ipa,
	GL_CODE_COMBINATIONS GCC,
	GL_CODE_COMBINATIONS GCP,
	per_person_names_f ppnf,
	per_person_names_f ppnfs,
	per_all_people_f papf,
	per_all_assignments_m paam,
	PER_ASSIGNMENT_SUPERVISORS_F PSSF
WHERE
	 ee.EXPENSE_REPORT_ID = eer.EXPENSE_REPORT_ID (+)
	AND ee.EXPENSE_ID = eed.EXPENSE_ID (+)
	AND ee.EXPENSE_TYPE_ID = eet.EXPENSE_TYPE_ID (+)
	AND ee.CREDIT_CARD_TRXN_ID = ect.CREDIT_CARD_TRXN_ID(+)
	AND eer.EXPENSE_REPORT_ID = eed.EXPENSE_REPORT_ID (+)
	AND eed.code_combination_id = gcc.code_combination_id (+)
	AND ee.person_id = papf.person_id
	AND papf.person_id = ppnf.person_id
	and papf.person_id = paam.person_id
	AND TRUNC(SYSDATE) BETWEEN nvl(ppnf.effective_start_date,sysdate-1) AND nvl(ppnf.effective_end_date,sysdate+1)
	AND TRUNC(SYSDATE) BETWEEN papf.effective_start_date AND papf.effective_end_date
	AND TRUNC(SYSDATE) BETWEEN NVL(ppnfs.effective_start_date,sysdate-1) AND nvl(ppnfs.effective_end_date,sysdate+1)
	AND TRUNC(SYSDATE) BETWEEN nvl(paam.effective_start_date,sysdate-1) AND nvl(paam.effective_end_date,sysdate+1)
	AND ppnf.name_type='GLOBAL'
	AND ppnfs.name_type(+) = 'GLOBAL'
	AND paam.default_code_comb_id = gcp.code_combination_id
	AND paam.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
	AND paam.assignment_type = 'E' 
	AND PSSF.manager_type = 'LINE_MANAGER'
	AND PPNF.PERSON_ID=PSSF.PERSON_ID (+)
	AND PSSF.MANAGER_ID=ppnfs.PERSON_ID(+)
	AND PSSF.PRIMARY_FLAG(+)='Y'
	AND trunc(sysdate) BETWEEN pssf.effective_start_date(+) AND pssf.effective_end_date(+)
	AND ((COALESCE (NULL, :P_EXPENSE_SOURCE) IS NULL) OR (ee.expense_source IN (:P_EXPENSE_SOURCE)))
	AND TO_CHAR(eer.EXPENSE_REPORT_ID) = aia.REFERENCE_KEY1 (+)
	AND (ee.ITEMIZATION_PARENT_EXPENSE_ID > 0 OR ee.ITEMIZATION_PARENT_EXPENSE_ID IS NULL)
	--AND TO_CHAR(aia.INVOICE_ID) = idpa.CALLING_APP_DOC_UNIQUE_REF2(+)
	--AND idpa.PAYMENT_ID = ipa.PAYMENT_ID(+)
	AND (:P_EXP_STATUS_CODE IS NULL OR eer.expense_Status_code=:P_EXP_STATUS_CODE)
	--AND nvl(eer.REPORT_SUBMIT_DATE,ect.TRANSACTION_DATE) BETWEEN NVL(:P_FROM_SUBMIT_DATE,nvl(eer.REPORT_SUBMIT_DATE,ect.TRANSACTION_DATE)) AND NVL(:P_TO_SUBMIT_DATE,nvl(eer.REPORT_SUBMIT_DATE,ect.TRANSACTION_DATE))
	AND nvl(ect.TRANSACTION_DATE,eer.REPORT_SUBMIT_DATE) BETWEEN NVL(:P_FROM_SUBMIT_DATE,nvl(ect.TRANSACTION_DATE,eer.REPORT_SUBMIT_DATE)) AND NVL(:P_TO_SUBMIT_DATE,nvl(ect.TRANSACTION_DATE,eer.REPORT_SUBMIT_DATE))
	AND ppnf.list_name=nvl(:P_full_name,ppnf.list_name)
	AND papf.person_number=nvl(:P_Emp_num,papf.person_number)
	AND ee.org_id in (select distinct ORG_ID 
					  from FUN_USER_ROLE_DATA_ASGNMNTS 
					  where user_guid = FND_GLOBAL.USER_GUID and active_flag ='Y')
ORDER BY gcp.segment2,ppnfs.list_name,eer.EXPENSE_REPORT_NUM   desc
