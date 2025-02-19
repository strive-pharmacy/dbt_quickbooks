--To disable this model, set the using_bill variable within your dbt_project.yml file to False.
{{ config(enabled=var('using_bill', True)) }}

with bills as (

    select *
    from {{ ref('stg_quickbooks__bill') }} 
),

bill_lines as (

    select *
    from {{ ref('stg_quickbooks__bill_line') }}
),

items as (

    select *
    from {{ref('stg_quickbooks__item')}}
),

final as (

    select
        bills.bill_id as transaction_id,
        bills.source_relation,
        bill_lines.index as transaction_line_id,
        bills.doc_number,
        'bill' as transaction_type,
        bills.transaction_date,
        coalesce(bill_lines.account_expense_account_id, items.expense_account_id) as account_id,
        bill_lines.account_expense_class_id as class_id,
        bills.department_id,
        coalesce(bill_lines.account_expense_customer_id, bill_lines.item_expense_customer_id) as customer_id,
        bills.vendor_id,
        coalesce(bill_lines.account_expense_billable_status, bill_lines.item_expense_billable_status) as billable_status,
        coalesce(bill_lines.description, items.name) as description,
        bill_lines.amount,
        bills.total_amount
    from bills

    inner join bill_lines 
        on bills.bill_id = bill_lines.bill_id
        and bills.bill_id = bill_lines.bill_id

    left join items
        on bill_lines.item_expense_item_id = items.item_id
        and bill_lines.source_relation = items.source_relation
)

select *
from final