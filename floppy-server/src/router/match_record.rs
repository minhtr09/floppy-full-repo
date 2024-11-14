use crate::db::bet_record;
use crate::db::match_record::{self, create_match_with_bet_records};
use crate::models::MatchRecord;
use crate::state::AppState;
use actix_web::{get, post, web, HttpResponse, Responder, Scope};

// Define a scope for match_record routes
pub fn match_record_scope() -> Scope {
    web::scope("/match_record")
        .service(get_all_match_records)
        .service(get_match_record_by_id)
        .service(create_match_record_handler)
        .service(create_match_with_bet_records_handler)
}

#[get("")]
async fn get_all_match_records(data: web::Data<AppState>) -> impl Responder {
    match match_record::get_all_match_records(&data.db_pool).await {
        Ok(records) => HttpResponse::Ok().json(records),
        Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
    }
}

#[post("/create_with_bet_records/{bet_id}")]
async fn create_match_with_bet_records_handler(
    data: web::Data<AppState>,
    match_record: web::Json<MatchRecord>,
    bet_id: web::Path<i64>,
) -> impl Responder {
    let bet_id_value = bet_id.into_inner();
    if bet_record::is_bet_exists(&data.db_pool, bet_id_value)
        .await
        .unwrap()
    {
        let match_id = match_record::create_match_record(&data.db_pool, match_record.into_inner())
            .await
            .unwrap();
        bet_record::update_match_id(&data.db_pool, bet_id_value, match_id as i64)
            .await
            .unwrap();
        HttpResponse::Created().finish()
    } else {
        match_record::create_match_with_bet_records(
            &data.db_pool,
            match_record.into_inner(),
            bet_id_value,
        )
        .await
        .unwrap();
        HttpResponse::Created().finish()
    }
}

#[get("/{id}")]
async fn get_match_record_by_id(id: web::Path<i32>, data: web::Data<AppState>) -> impl Responder {
    let id_value = id.into_inner();

    match match_record::get_match_by_id(&data.db_pool, id_value).await {
        Ok(record) => HttpResponse::Ok().json(record),
        Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
    }
}

#[post("")]
async fn create_match_record_handler(
    data: web::Data<AppState>,
    match_record: web::Json<MatchRecord>,
) -> impl Responder {
    let match_record = match_record.into_inner();
    match match_record::create_match_record(&data.db_pool, match_record).await {
        Ok(_) => HttpResponse::Created().finish(),
        Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
    }
}
