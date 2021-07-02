import { HttpClient } from '@angular/common/http';
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {

  gettingIn: {
    cafe: string,
    phone: string,
    agreeToOfferInfo: boolean
  } = {
    cafe: undefined,
    phone: undefined,
    agreeToOfferInfo: true
  };

  gettingOut: string;

  ios: IO[] = [];
  disobeyeds: IO[] = [];

  constructor(
    private http: HttpClient
  ) { }

  async onGettingInSubmit() {
    try {
      await this.http.post<void>('/api/getting-in', this.gettingIn).toPromise();
      alert('submitted successfully\n' + JSON.stringify(this.gettingIn, null, 2));

    } catch (err) {
      console.log(err);
    }
  }

  async onGettingOutSubmit() {
    try {
      const io = await this.http.get<IO>(`/api/ios/${this.gettingOut}`).toPromise();
      if ( new Date().getTime() - io.in_ms > 1000 * 60 * 60 ) {
        alert(`the customer '${this.gettingOut}' stayed over 1 hour`);
      }
      await this.http.post<void>('/api/getting-out', this.gettingOut).toPromise();
      alert('got out successfully');
    } catch(err) {
      console.log(err);
    }
  }

  async getAllIOs() {
    this.ios = await this.http.get<IO[]>('/api/ios').toPromise();
  }

  async getDisobeyeds() {
    this.disobeyeds = await this.http.get<IO[]>('/api/check-disobeyed').toPromise();
  }

}

class IO {
  key?: string;
  cafe: string;
  phone: string;  // ex) 01012345678
  in_ms: number;  // millisecond
  out_ms: number; // millisecond
  agreeToOfferInfo: boolean;
}

