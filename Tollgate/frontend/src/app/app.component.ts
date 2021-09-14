import { HttpClient } from '@angular/common/http';
import { Component, OnInit } from '@angular/core';
import { Car, Driver, Record } from 'src/model/record';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {

  cars: Car[] = [];
  drivers: Driver[] = [];
  records: Record[] = [];

  charge_item: {
    car_num: string,
    tollgate: string
  } = {
    car_num: undefined,
    tollgate: undefined
  };

  pay_item: {
    phone: string,
    payed: number
  } = {
    phone: undefined,
    payed: 0
  };

  constructor(
    private http: HttpClient
  ) { }

  async ngOnInit() {}

  async getAllCars() {
    this.cars = await this.http.get<Car[]>(`/api/cars`).toPromise();
  }

  async getAllDrivers() {
    this.drivers = await this.http.get<Driver[]>(`/api/drivers`).toPromise();
  }

  async getAllRecords() {
    this.records = await this.http.get<Record[]>('/api/records').toPromise();
  }

  async charge() {
    await this.http.post<void>(`/api/charge`, this.charge_item).toPromise();
    alert('done');
  }

  async pay() {
    await this.http.post<void>(`/api/pay`, this.pay_item).toPromise();
    alert('done');
  }

}
