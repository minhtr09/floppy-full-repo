use crate::db::bet_record;
use crate::models::BetRecord;
use crate::state::AppState;
use actix_web::{get, post, web, HttpResponse, Responder, Scope};

// Define a scope for match_record routes
pub fn bet_record_scope() -> Scope {
    web::scope("/bet_record")
        // .service(get_all_bet_records)
        .service(get_bet_record_by_id)
        .service(create_bet_record)
}

// #[get("")]
// async fn get_all_bet_records(data: web::Data<AppState>) -> impl Responder {
//     match bet_record::get_all_bet_records(&data.db_pool).await {
//         Ok(records) => HttpResponse::Ok().json(records),
//         Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
//     }
// }

#[get("/{id}")]
async fn get_bet_record_by_id(id: web::Path<i64>, data: web::Data<AppState>) -> impl Responder {
    let id_value = id.into_inner();

    match bet_record::get_bet_record_by_id(&data.db_pool, id_value).await {
        Ok(record) => HttpResponse::Ok().json(record),
        Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
    }
}

#[post("")]
async fn create_bet_record(
    data: web::Data<AppState>,
    bet_record: web::Json<BetRecord>,
) -> impl Responder {
    let bet_record = bet_record.into_inner();
    match bet_record::create_bet_record(&data.db_pool, bet_record).await {
        Ok(_) => HttpResponse::Created().finish(),
        Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
    }
}
