import faker
import psycopg2

import random
from datetime import datetime

fake = faker.Faker()


def generate_transaction():
    user = fake.simple_profile()
    return {
        'transaction_id': fake.uuid4(),
        'userId': user['username'],
        'timestamp': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
        'amount': round(random.uniform(10, 1000), 2),
        'currency': random.choice(['USD', 'GBP', 'EUR']),
        'city': fake.city(),
        'country': fake.country(),
        'merchant_name': fake.company(),
        'payment_method': random.choice(
            ['credit_card', 'debit_card', 'online_transfer']
        ),
        'ip_address': fake.ipv4(),
        'voucher_code': random.choice(['', 'DISCOUNT10', '']),
        'affiliate_id': fake.uuid4(),
    }


if __name__ == '__main__':
    conn = psycopg2.connect(
        database='financial_db',
        user='postgres',
        password='postgres',
        host='127.0.0.1',
        port='5432',
    )
    conn.autocommit = False

    cursor = conn.cursor()

    transaction = generate_transaction()
    print(transaction)

    cursor.execute(
        '''
            INSERT INTO transactions(transaction_id, user_id, timestamp, amount, currency, city, country, merchant_name,
            payment_method, ip_address, voucher_code, affiliate_id) VALUES ({})
        '''.format(
            ', '.join(['%s'] * 12)
        ),
        tuple(transaction.values())  # it is flat
    )
    cursor.close()
    conn.commit()
